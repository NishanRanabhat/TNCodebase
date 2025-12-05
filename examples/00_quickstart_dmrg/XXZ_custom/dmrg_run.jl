#!/usr/bin/env julia
# examples/models/custom/xxz/run_dmrg.jl
#
# Custom XXZ Model: Complete DMRG Ground State Search
#
# This example demonstrates:
# - Custom model building using channels (not prebuilt template)
# - Config-driven workflow (everything in config.json)
# - Full control over Hamiltonian terms
# - Energy convergence tracking
# - Automatic data saving with hash-based indexing

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", ".."))

using TNCodebase
using JSON

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "dmrg_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration loaded from: dmrg_config.json")
println("\n" * "─"^70)
println("SYSTEM:")
println("  Type: $(config["system"]["type"])")
println("  Size: N = $(config["system"]["N"])")

println("\nMODEL: $(config["model"]["name"])")
println("  Description: $(config["model"]["params"]["description"])")
println("  dtype: $(config["model"]["params"]["dtype"])")

println("\n  CHANNELS:")
for (i, ch) in enumerate(config["model"]["params"]["channels"])
    println("  [$i] $(ch["type"]):")
    if ch["type"] == "FiniteRangeCoupling"
        println("      $(ch["op1"]) ⊗ $(ch["op2"]), range=$(ch["range"]), strength=$(ch["strength"])")
    elseif ch["type"] == "Field"
        println("      $(ch["op"]), strength=$(ch["strength"])")
    elseif ch["type"] == "PowerLawCoupling"
        println("      $(ch["op1"]) ⊗ $(ch["op2"]), α=$(ch["alpha"]), strength=$(ch["strength"])")
    end
    if haskey(ch, "description")
        println("      → $(ch["description"])")
    end
end

println("\nINITIAL STATE: $(config["state"]["type"])")
println("  Bond dimension: $(config["state"]["params"]["bond_dim"])")

println("\nALGORITHM: $(config["algorithm"]["type"])")
println("  Sweeps:       $(config["algorithm"]["run"]["n_sweeps"])")
println("  χ_max:        $(config["algorithm"]["options"]["chi_max"])")
println("  Cutoff:       $(config["algorithm"]["options"]["cutoff"])")
println("  Solver:       $(config["algorithm"]["solver"]["type"])")
println("─"^70)

# ============================================================================
# RUN DMRG SIMULATION
# ============================================================================

println("\nStarting DMRG simulation...")

# Specify data directory relative to package root to save the results
data_dir = joinpath(@__DIR__, "..", "..", "..", "data")

# Run simulation - returns final state, run_id, and run_directory
state, run_id, run_dir = run_simulation_from_config(config, base_dir=data_dir)

println("\n" * "="^70)
println("SIMULATION COMPLETE!")
println("="^70)

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

# Load metadata to get convergence information
metadata_file = joinpath(run_dir, "metadata.json")
metadata = JSON.parsefile(metadata_file)

println("\nRUN INFORMATION:")
println("  Run ID:        $run_id")
println("  Data saved to: $run_dir")

println("\nCONVERGENCE SUMMARY:")
sweep_data = metadata["sweep_data"]
n_sweeps = length(sweep_data)

# First sweep
first_sweep = sweep_data[1]
println("  Sweep 1:")
println("    Energy:     $(first_sweep["energy"])")
println("    Bond dim:   $(first_sweep["max_bond_dim"])")

# Middle sweep (around sweep 10)
mid_idx = min(10, n_sweeps)
mid_sweep = sweep_data[mid_idx]
println("  Sweep $mid_idx:")
println("    Energy:     $(mid_sweep["energy"])")
println("    Bond dim:   $(mid_sweep["max_bond_dim"])")

# Final sweep
final_sweep = sweep_data[end]
println("  Sweep $n_sweeps (final):")
println("    Energy:     $(final_sweep["energy"])")
println("    Bond dim:   $(final_sweep["max_bond_dim"])")

# Energy change in last sweep
if n_sweeps > 1
    prev_energy = sweep_data[end-1]["energy"]
    energy_change = abs(final_sweep["energy"] - prev_energy)
    println("\nCONVERGENCE CHECK:")
    println("  Energy change (last sweep): $(energy_change)")
    if energy_change < 1e-6
        println("  ✓ Converged! (ΔE < 10⁻⁶)")
    else
        println("  ⚠ Not fully converged (ΔE = $(energy_change))")
    end
end

println("\n" * "="^70)
println("Success! You've run a custom XXZ DMRG simulation with TNCodebase.")
println("="^70)
