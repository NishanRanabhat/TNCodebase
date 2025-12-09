#!/usr/bin/env julia
#
# Long-Range Ising TDVP Time Evolution (Custom Channels)
#
# Demonstrates domain wall spreading with power-law interactions
# using custom channel definition

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Long-Range Ising (Custom): TDVP Time Evolution")
println("="^70)

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "tdvp_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration loaded from: tdvp_config.json")
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
    if ch["type"] == "PowerLawCoupling"
        println("      $(ch["op1"]) ⊗ $(ch["op2"]), α=$(ch["alpha"]), n_exp=$(ch["n_exp"]), strength=$(ch["strength"])")
    elseif ch["type"] == "Field"
        println("      $(ch["op"]), strength=$(ch["strength"])")
    elseif ch["type"] == "FiniteRangeCoupling"
        println("      $(ch["op1"]) ⊗ $(ch["op2"]), range=$(ch["range"]), strength=$(ch["strength"])")
    end
    if haskey(ch, "description")
        println("      → $(ch["description"])")
    end
end

println("\nINITIAL STATE: $(config["state"]["name"])")
println("  Direction:     $(config["state"]["params"]["spin_direction"])")
println("  Start index:   $(config["state"]["params"]["start_index"])")
println("  Domain size:   $(config["state"]["params"]["domain_size"])")

println("\nALGORITHM: $(config["algorithm"]["type"])")
println("  Time step:     dt = $(config["algorithm"]["options"]["dt"])")
println("  Sweeps:        $(config["algorithm"]["run"]["n_sweeps"])")
println("  Total time:    T = $(config["algorithm"]["run"]["n_sweeps"] * config["algorithm"]["options"]["dt"])")
println("  χ_max:         $(config["algorithm"]["options"]["chi_max"])")
println("  Cutoff:        $(config["algorithm"]["options"]["cutoff"])")
println("  Solver:        $(config["algorithm"]["solver"]["type"])")
println("  Krylov dim:    $(config["algorithm"]["solver"]["krylov_dim"])")
println("─"^70)

# ============================================================================
# RUN TDVP SIMULATION
# ============================================================================

println("\nStarting TDVP evolution...")

# Specify data directory relative to package root
data_dir = joinpath(@__DIR__, "..", "..", "..", "data")

# Run simulation - returns final state, run_id, and run_directory
state, run_id, run_dir = run_simulation_from_config(config, base_dir=data_dir)

println("\n" * "="^70)
println("TIME EVOLUTION COMPLETE!")
println("="^70)

# ============================================================================
# DISPLAY RESULTS
# ============================================================================

# Load metadata to get evolution information
metadata_file = joinpath(run_dir, "metadata.json")
metadata = JSON.parsefile(metadata_file)

println("\nRUN INFORMATION:")
println("  Run ID:        $run_id")
println("  Data saved to: $run_dir")

println("\nEVOLUTION SUMMARY:")
sweep_data = metadata["sweep_data"]
n_sweeps = length(sweep_data)

# First sweep
first_sweep = sweep_data[1]
println("  Sweep 1:")
println("    Time:       $(first_sweep["time"])")
println("    Bond dim:   $(first_sweep["max_bond_dim"])")

# Middle sweep
mid_idx = min(125, n_sweeps)
if mid_idx > 1
    mid_sweep = sweep_data[mid_idx]
    println("  Sweep $mid_idx:")
    println("    Time:       $(mid_sweep["time"])")
    println("    Bond dim:   $(mid_sweep["max_bond_dim"])")
end

# Final sweep
final_sweep = sweep_data[end]
println("  Sweep $n_sweeps (final):")
println("    Time:       $(final_sweep["time"])")
println("    Bond dim:   $(final_sweep["max_bond_dim"])")

println("\n" * "="^70)
println("Success! Long-range Ising (custom) TDVP evolution completed.")
println("="^70)
