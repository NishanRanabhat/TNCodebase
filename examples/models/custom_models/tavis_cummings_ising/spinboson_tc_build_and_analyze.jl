#!/usr/bin/env julia
# examples/models/custom/spinboson_longrange/build_and_analyze.jl
#
# Spin-Boson Long-Range Model: Ising-Dicke with Power-Law Interactions
#
# This example demonstrates:
# - Spin-boson system construction (heterogeneous sites)
# - Long-range interactions via FSM (works with spin-boson!)
# - Correct Tavis-Cummings coupling (Sp/Sm operators)
# - Channel-by-channel building from scratch
#
# PHYSICS: Collective light-matter interaction + long-range spin interactions
# Applications: Cavity QED, trapped ions, Rydberg atoms

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON
using LinearAlgebra

println("="^70)
println("SPIN-BOSON MODEL: Long-Range Ising-Dicke")
println("="^70)

# ============================================================================
# THEORETICAL BACKGROUND
# ============================================================================

println("\n" * "─"^70)
println("THE PHYSICS:")
println("─"^70)
println("""
HAMILTONIAN:
  H = ω b†b + J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + g Σᵢ (a σ⁺ᵢ + a† σ⁻ᵢ)

COMPONENTS:
  1. Boson energy:         ω b†b
     → Photon mode (cavity) or phonon mode (ion trap)
  
  2. Long-range Ising:     J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α
     → Coulomb (α≈0), dipolar (α=3), power-law
     → Uses FSM for efficient MPO representation!
  
  3. Tavis-Cummings:       g Σᵢ (a σ⁺ᵢ + a† σ⁻ᵢ)
     → Collective light-matter coupling
     → Conserves total excitations (photons + spin-ups)
     → a σ⁺ᵢ: absorb photon, raise spin
     → a† σ⁻ᵢ: emit photon, lower spin

PHYSICAL SYSTEMS:
  • Trapped ions: Coulomb interaction + phonon modes
  • Cavity QED: Rydberg atoms + photon cavity
  • Circuit QED: Superconducting qubits + resonator
  • Cold atoms: Dipolar gases in optical cavity

KEY PHENOMENA:
  • Quantum phase transitions (normal ↔ superradiant)
  • Long-range magnetic order
  • Cavity-mediated interactions
""")

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

println("\n" * "─"^70)
println("CONFIGURATION:")
println("─"^70)

config_file = joinpath(@__DIR__, "spinboson_tc_model_config.json")
config = JSON.parsefile(config_file)

N_spins = config["model"]["params"]["N_spins"]
nmax = config["model"]["params"]["nmax"]
channels = config["model"]["params"]["channels"]

println("System:")
println("  Number of spins:   N = $N_spins")
println("  Boson cutoff:      nmax = $nmax")
println("  Total sites:       $(N_spins + 1) (1 boson + $N_spins spins)")

# Count channels
n_spin = length(get(channels, "spin_channels", []))
n_boson = length(get(channels, "boson_channels", []))
n_spinboson = length(get(channels, "spinboson_channels", []))
n_total = n_spin + n_boson + n_spinboson

println("\nChannels ($n_total total):")

println("  Spin channels ($n_spin):")
for (i, ch) in enumerate(get(channels, "spin_channels", []))
    println("    $i. $(ch["type"])")
    if haskey(ch, "description")
        println("       → $(ch["description"])")
    end
end

println("  Boson channels ($n_boson):")
for (i, ch) in enumerate(get(channels, "boson_channels", []))
    println("    $i. BosonOnly (op: $(ch["op"]))")
    if haskey(ch, "description")
        println("       → $(ch["description"])")
    end
end

println("  SpinBoson channels ($n_spinboson):")
for (i, ch) in enumerate(get(channels, "spinboson_channels", []))
    println("    $i. SpinBosonInteraction (boson_op: $(ch["boson_op"]))")
    if haskey(ch, "description")
        println("       → $(ch["description"])")
    end
end

# Extract parameters
pl_channel = channels["spin_channels"][1]  # PowerLawCoupling
α = pl_channel["alpha"]
J = pl_channel["strength"]
n_exp = pl_channel["n_exp"]

g = channels["spinboson_channels"][1]["strength"]  # TC coupling
ω = channels["boson_channels"][1]["strength"]      # Boson frequency

println("\nPhysical parameters:")
println("  Ising coupling:     J = $J")
println("  Power-law exponent: α = $α")
println("  TC coupling:        g = $g")
println("  Boson frequency:    ω = $ω")
println("  Exponentials (FSM): K = $n_exp")

# ============================================================================
# BUILD MPO - CHANNEL BY CHANNEL
# ============================================================================

println("\n" * "="^70)
println("CHANNEL-BY-CHANNEL CONSTRUCTION:")
println("="^70)

println("\nThis demonstrates how each physical term becomes an MPO channel:")

println("\n1️⃣  SPIN CHANNELS (auto-wrapped with boson identity):")
println("    Long-Range Ising: J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α")
println("    Method:  Sum-of-exponentials decomposition")
println("    Result:  FSM with K=$n_exp states")
println("    Efficiency: Bond dim O(K) instead of O(N)")

println("\n2️⃣  BOSON CHANNELS:")
println("    Boson Energy: ω b†b")
println("    Channel: Diagonal on boson site")
println("    Meaning: Photon/phonon frequency")

println("\n3️⃣  SPINBOSON CHANNELS (explicit coupling):")
println("    Absorption: g a Σᵢ σ⁺ᵢ")
println("    Emission:   g a† Σᵢ σ⁻ᵢ")
println("    Meaning: Photon absorbed/emitted ↔ spin raised/lowered")

println("\n" * "─"^70)
println("Building complete MPO from all channels...")
mpo = build_mpo_from_config(config)
println("✓ MPO constructed successfully")

# ============================================================================
# ANALYZE MPO STRUCTURE
# ============================================================================

println("\n" * "="^70)
println("MPO STRUCTURE ANALYSIS:")
println("="^70)

# Inspect tensor dimensions
println("\nTensor dimensions [χ_left × d × d × χ_right]:")
println("  Site 1 (boson):  [$(size(mpo.tensors[1], 1)) × $(size(mpo.tensors[1], 2)) × $(size(mpo.tensors[1], 3)) × $(size(mpo.tensors[1], 4))]")
for i in 2:min(4, length(mpo.tensors))
    dims = size(mpo.tensors[i])
    println("  Site $i (spin):   [$(dims[1]) × $(dims[2]) × $(dims[3]) × $(dims[4])]")
end
println("  ...")
dims_last = size(mpo.tensors[end])
println("  Site $(length(mpo.tensors)) (spin):   [$(dims_last[1]) × $(dims_last[2]) × $(dims_last[3]) × $(dims_last[4])]")

# Calculate bond dimensions
bond_dims_left = [size(W, 1) for W in mpo.tensors]
bond_dims_right = [size(W, 4) for W in mpo.tensors]

max_bond_dim = maximum([maximum(bond_dims_left), maximum(bond_dims_right)])

println("\nBond dimensions (left):  ", bond_dims_left[1:min(5, length(bond_dims_left))], "...")
println("Bond dimensions (right): ", bond_dims_right[1:min(5, length(bond_dims_right))], "...")

println("\n" * "─"^70)
println("MAXIMUM BOND DIMENSION: χ = $max_bond_dim")
println("─"^70)
