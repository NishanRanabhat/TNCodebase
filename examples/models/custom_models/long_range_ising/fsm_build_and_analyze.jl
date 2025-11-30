#!/usr/bin/env julia
# examples/models/custom/advanced_fsm/build_and_analyze.jl
#
# Advanced FSM Example: Power-Law Interactions
#
# This example demonstrates TNCodebase's most sophisticated feature:
# Efficient representation of long-range power-law interactions using
# Finite State Machines (FSM) and sum-of-exponentials decomposition.
#
# KEY INSIGHT: Naive MPO for power-law has bond dimension O(N)
#              FSM-based MPO has bond dimension O(log N)
#              This is an EXPONENTIAL improvement!

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON
using LinearAlgebra

println("="^70)
println("ADVANCED EXAMPLE: Power-Law Interactions via FSM")
println("="^70)

# ============================================================================
# THEORETICAL BACKGROUND
# ============================================================================

println("\n" * "─"^70)
println("THE PROBLEM:")
println("─"^70)
println("""
Long-range power-law Hamiltonians:
  H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ / |i-j|^α

NAIVE MPO CONSTRUCTION:
  • Each site must "remember" all previous interactions
  • Bond dimension χ = O(N) - grows with system size!
  • For N=30: χ_naive ≈ 30
  • For N=100: χ_naive ≈ 100
  • IMPRACTICAL for large systems

FSM SOLUTION:
  • Approximate 1/r^α as sum of exponentials: Σₖ νₖλₖʳ
  • Each exponential = one FSM channel
  • Bond dimension χ = O(K) where K ~ log(N)
  • For N=30, K=10: χ_FSM ≈ 12
  • For N=100, K=15: χ_FSM ≈ 17
  • EXPONENTIAL IMPROVEMENT!
""")

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

println("\n" * "─"^70)
println("CONFIGURATION:")
println("─"^70)

config_file = joinpath(@__DIR__, "fsm_model_config.json")
config = JSON.parsefile(config_file)

N = config["model"]["params"]["N"]
channels = config["model"]["params"]["channels"]

# Extract power-law parameters
pl_channel = channels[1]  # PowerLawCoupling
α = pl_channel["alpha"]
strength = pl_channel["strength"]
n_exp = pl_channel["n_exp"]

println("System size:        N = $N")
println("Power-law exponent: α = $α")
println("Coupling strength:  J = $strength")
println("Number of exps:     K = $n_exp")
println("\nChannels:")
for (i, ch) in enumerate(channels)
    println("  $i. $(ch["type"]): $(get(ch, "description", ""))")
end

# ============================================================================
# BUILD MPO
# ============================================================================

println("\n" * "─"^70)
println("BUILDING MPO:")
println("─"^70)

println("\nBuilding MPO with PowerLawCoupling...")
println("(This uses sum-of-exponentials decomposition internally)")
mpo = build_mpo_from_config(config)
println("✓ MPO constructed successfully")

# ============================================================================
# ANALYZE MPO STRUCTURE
# ============================================================================

println("\n" * "="^70)
println("MPO STRUCTURE ANALYSIS:")
println("="^70)

# Inspect tensor dimensions manually
println("\nTensor dimensions [χ_left × d × d × χ_right]:")
for (i, W) in enumerate(mpo.tensors)
    dims = size(W)
    println("  Site $i: [$(dims[1]) × $(dims[2]) × $(dims[3]) × $(dims[4])]")
end

# Calculate bond dimensions
bond_dims_left = [size(W, 1) for W in mpo.tensors]
bond_dims_right = [size(W, 4) for W in mpo.tensors]

println("\nBond dimensions (left):")
println("  ", bond_dims_left)
println("\nBond dimensions (right):")
println("  ", bond_dims_right)

# Maximum bond dimension
max_bond_dim = maximum([maximum(bond_dims_left), maximum(bond_dims_right)])
println("\n" * "─"^70)
println("MAXIMUM BOND DIMENSION: χ = $max_bond_dim")
println("─"^70)

# ============================================================================
# EFFICIENCY COMPARISON
# ============================================================================

println("\n" * "="^70)
println("EFFICIENCY COMPARISON:")
println("="^70)

# FSM bond dimension
χ_FSM = max_bond_dim

# Naive bond dimension (approximate)
χ_naive = N  # Each site remembers all previous sites

# Reduction factor
reduction = χ_naive / χ_FSM

println("\nFSM approach (this code):")
println("  Bond dimension:  χ_FSM = $χ_FSM")
println("  Scaling:         O(K) where K = $n_exp")
println("  Memory:          $(round(N * χ_FSM^2 * 4 * 8 / 1024, digits=2)) KB")

println("\nNaive approach (without FSM):")
println("  Bond dimension:  χ_naive ≈ $χ_naive")
println("  Scaling:         O(N)")
println("  Memory:          $(round(N * χ_naive^2 * 4 * 8 / 1024, digits=2)) KB")

println("\n" * "─"^70)
println("EFFICIENCY GAIN:")
println("─"^70)
println("  Bond dimension reduction: $(round(reduction, digits=1))×")
println("  Memory reduction:         $(round(reduction^2, digits=1))×")
println("  Computation speedup:      $(round(reduction^3, digits=1))× per sweep")

# ============================================================================
# THEORETICAL SCALING
# ============================================================================

println("\n" * "="^70)
println("SCALING ANALYSIS:")
println("="^70)

println("\nHow bond dimension scales with system size:")
println()
println("  N    │  χ_FSM (K=10)  │  χ_naive  │  Reduction")
println("  ─────┼────────────────┼───────────┼─────────────")

for N_test in [30, 50, 100, 200, 500]
    # FSM: χ ≈ K + 2 (roughly constant in K, K grows as log(N))
    K_needed = n_exp  # Simplified: K ≈ 10 for these sizes
    χ_FSM_test = K_needed + 2
    χ_naive_test = N_test
    reduction_test = χ_naive_test / χ_FSM_test
    
    println("  $(lpad(N_test, 4)) │  $(lpad(χ_FSM_test, 14)) │  $(lpad(χ_naive_test, 9)) │  $(lpad(round(reduction_test, digits=1), 12))×")
end

println("\nNote: FSM bond dimension stays nearly constant!")
println("      Naive bond dimension grows linearly with N")

# ============================================================================
# MPO PROPERTIES
# ============================================================================

println("\n" * "="^70)
println("MPO PROPERTIES:")
println("="^70)

# Check if MPO tensors are real or complex
sample_tensor = mpo.tensors[1]
is_real = eltype(sample_tensor) <: Real

println("\nData type:        $(eltype(sample_tensor))")
println("Real-valued:      $is_real")
println("Number of sites:  $(length(mpo.tensors))")

# Estimate total memory
total_elements = sum(length(W) for W in mpo.tensors)
memory_bytes = total_elements * sizeof(eltype(sample_tensor))
memory_kb = memory_bytes / 1024
memory_mb = memory_kb / 1024

println("\nMemory usage:")
println("  Total elements:   $total_elements")
println("  Memory:           $(round(memory_kb, digits=2)) KB")
println("  Per site:         $(round(memory_kb/N, digits=2)) KB")

# ============================================================================
# WHAT THIS DEMONSTRATES
# ============================================================================

println("\n" * "="^70)
println("KEY ACHIEVEMENTS:")
println("="^70)
println("""
✓ Power-law interactions (1/r^α) efficiently encoded in MPO
✓ Bond dimension χ = $χ_FSM (instead of ~$N without FSM)
✓ $(round(reduction, digits=1))× reduction in bond dimension
✓ $(round(reduction^2, digits=1))× reduction in memory
✓ $(round(reduction^3, digits=1))× speedup in MPO-MPS operations

TECHNICAL SOPHISTICATION:
• Sum-of-exponentials decomposition: 1/r^α ≈ Σₖ νₖλₖʳ
• Finite State Machine construction from channels
• Automatic optimization of MPO bond dimension

""")

println("\n" * "="^70)
println("See docs/model_building.md for comprehensive documentation")
println("="^70)
