#!/usr/bin/env julia
#
# TDVP Time Evolution Example
#
# This example demonstrates:
# - Config-driven time evolution workflow
# - Automatic model building (TFIM using prebuilt template)
# - Polarized initial state
# - TDVP algorithm for quantum dynamics
# - Automatic data saving with hash-based indexing

# ============================================================================
# SETUP
# ============================================================================

using Pkg
Pkg.activate(joinpath(@__DIR__, "..","..",".."))

using TNCodebase
using JSON

println("="^70)
println("TDVP Time Evolution")
println("="^70)

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "tdvp_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration loaded from: config.json")
println("\n" * "─"^70)
println("SYSTEM:")
println("  Type: $(config["system"]["type"])")
println("  Size: N = $(config["system"]["N"])")

println("\nMODEL: $(config["model"]["name"])")
println("  J (coupling): $(config["model"]["params"]["J"])")
println("  h (field):    $(config["model"]["params"]["h"])")
println("  Coupling dir: $(config["model"]["params"]["coupling_dir"])")
println("  Field dir:    $(config["model"]["params"]["field_dir"])")

println("\nINITIAL STATE: $(config["state"]["name"])")
println("  Direction:    $(config["state"]["params"]["spin_direction"])")
println("  Eigenstate:   $(config["state"]["params"]["eigenstate"])")

println("\nALGORITHM: $(config["algorithm"]["type"])")
println("  Time step:    dt = $(config["algorithm"]["options"]["dt"])")
println("  Sweeps:       $(config["algorithm"]["run"]["n_sweeps"])")
println("  χ_max:        $(config["algorithm"]["options"]["chi_max"])")
println("  Cutoff:       $(config["algorithm"]["options"]["cutoff"])")
println("  Solver:       $(config["algorithm"]["solver"]["type"])")
println("  Krylov dim:   $(config["algorithm"]["solver"]["krylov_dim"])")
println("  Evol type:    $(config["algorithm"]["solver"]["evol_type"])")

println("─"^70)

# ============================================================================
# RUN TDVP SIMULATION
# ============================================================================

println("\nStarting TDVP evolution...")

# Specify data directory relative to package root
data_dir = joinpath(@__DIR__, "..","..","..","data")

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

# Middle sweep (around sweep 100)
mid_idx = min(100, n_sweeps)
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
println("Success! TDVP evolution completed.")
println("="^70)