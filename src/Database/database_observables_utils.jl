# ============================================================================
# OBSERVABLE DATABASE MANAGEMENT SYSTEM
# ============================================================================
#
# This module provides database functionality for managing observable
# calculations on tensor network simulation data.
#
# STRUCTURE:
#   observables/
#   ├── observables_index.json
#   └── {algorithm}/
#       └── {simulation_run_id}/
#           └── {observable_run_id}/
#               ├── observable_config.json
#               ├── metadata.json
#               └── observable_sweep_*.jld2
#
# TYPICAL WORKFLOW:
#   1. Setup: obs_run_id, obs_run_dir = _setup_observable_directory(obs_config, sim_run_id, algorithm)
#   2. Calculate & Save: _save_observable_sweep(obs_value, obs_run_dir, sweep; extra_data=...)
#   3. Finalize: _finalize_observable_run(obs_run_dir, status="completed")
#   4. Later: obs_value = load_observable_sweep(obs_run_dir, sweep)
#
# ============================================================================

using JSON
using SHA
using Dates #: now, format
using JLD2
using Printf

# ============================================================================
# PART 1: HASH AND ID GENERATION
# ============================================================================

"""
    _compute_observable_config_hash(obs_config::Dict) -> String

Compute an 8-character hash that uniquely identifies an observable configuration.

The hash is deterministic: same observable config always produces the same hash.
This enables finding duplicate calculations.

# Returns
- String: 8 hex characters (e.g., "f4b2c3d1")
"""
function _compute_observable_config_hash(obs_config::Dict)
    # Convert to canonical JSON
    config_str = JSON.json(obs_config, 2)
    
    # Compute SHA256 and take first 8 characters
    hash_full = bytes2hex(sha256(config_str))
    
    return hash_full[1:8]
end

"""
    _generate_observable_run_id(obs_config::Dict) -> String

Generate a unique identifier for an observable calculation run.

Format: YYYYMMDD_HHMMSS_HHHHHHHH
        └─ timestamp ─┘ └─ hash ─┘

# Returns
- String: Unique observable run ID (e.g., "20241104_153045_f4b2c3d1")
"""
function _generate_observable_run_id(obs_config::Dict)
    # Get current timestamp
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")
    
    # Get observable config hash
    obs_hash = _compute_observable_config_hash(obs_config)
    
    # Combine: timestamp_hash
    return "$(timestamp)_$(obs_hash)"
end

# ============================================================================
# PART 2: SETUP AND INITIALIZATION
# ============================================================================

"""
    _setup_observable_directory(obs_config, sim_run_id, algorithm; obs_base_dir="observables") 
        -> (String, String)

Initialize directory structure and files for a new observable calculation.

Called ONCE at the start of each observable calculation, before processing sweeps.

# What it creates
```
observables/
├── observables_index.json       ← Updated with new calculation
└── {algorithm}/
    └── {sim_run_id}/
        └── {obs_run_id}/
            ├── observable_config.json
            └── metadata.json
```

# Arguments
- `obs_config::Dict`: Observable configuration
- `sim_run_id::String`: Simulation run identifier (links to data/)
- `algorithm::String`: Algorithm type ("dmrg" or "tdvp")
- `obs_base_dir::String`: Root observable directory (default: "observables")

# Returns
- `obs_run_id::String`: Unique identifier for this observable calculation
- `obs_run_dir::String`: Full path to observable run directory

# Example
```julia
obs_run_id, obs_run_dir = _setup_observable_directory(
    obs_config, 
    "20241103_142530_a3f5b2c1", 
    "tdvp"
)
```
"""
function _setup_observable_directory(obs_config::Dict, 
                                    sim_run_id::String, 
                                    algorithm::String; 
                                    obs_base_dir::String="observables")
    # Generate unique observable run ID
    obs_run_id = _generate_observable_run_id(obs_config)
    
    # Create full path: observables/algorithm/sim_run_id/obs_run_id
    obs_run_dir = joinpath(obs_base_dir, algorithm, sim_run_id, obs_run_id)
    
    # Create directory
    mkpath(obs_run_dir)
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Save observable_config.json
    # ═══════════════════════════════════════════════════════════════════════════
    obs_config_path = joinpath(obs_run_dir, "observable_config.json")
    open(obs_config_path, "w") do f
        JSON.print(f, obs_config, 2)
    end
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Initialize metadata.json
    # ═══════════════════════════════════════════════════════════════════════════
    metadata = Dict(
        "obs_run_id" => obs_run_id,
        "sim_run_id" => sim_run_id,
        "algorithm" => algorithm,
        "observable_type" => obs_config["observable"]["type"],
        "start_time" => string(now()),
        "status" => "running",
        "sweeps_processed" => 0,
        "last_update" => string(now()),
        "sweep_data" => []  # Will fill during calculation
    )
    
    metadata_path = joinpath(obs_run_dir, "metadata.json")
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
    
    # ═══════════════════════════════════════════════════════════════════════════
    # Update master observable index
    # ═══════════════════════════════════════════════════════════════════════════
    _update_observable_index(obs_config, sim_run_id, obs_run_id, obs_run_dir, obs_base_dir)
    
    println("✓ Setup observable directory: $obs_run_dir")
    
    return obs_run_id, obs_run_dir
end

"""
    _update_observable_index(obs_config, sim_run_id, obs_run_id, obs_run_dir, obs_base_dir)

Update the master observable index with a new calculation entry.

The index maps: sim_run_id → [list of observable calculations]

This enables quick lookup of all observables calculated for a simulation.
"""
function _update_observable_index(obs_config::Dict, 
                                sim_run_id::String,
                                obs_run_id::String, 
                                obs_run_dir::String,
                                obs_base_dir::String)
    index_file = joinpath(obs_base_dir, "observables_index.json")
    
    # Load existing index or create new
    if isfile(index_file)
        index = JSON.parsefile(index_file)
    else
        index = Dict(
            "by_simulation" => Dict(),
            "last_updated" => string(now())
        )
    end
    
    # Prepare entry
    entry = Dict(
        "obs_run_id" => obs_run_id,
        "obs_run_dir" => obs_run_dir,
        "observable_type" => obs_config["observable"]["type"],
        "observable_params" => obs_config["observable"]["params"],
        "timestamp" => string(now()),
        "obs_config_hash" => _compute_observable_config_hash(obs_config)
    )
    
    # Add to index under sim_run_id
    if !haskey(index["by_simulation"], sim_run_id)
        index["by_simulation"][sim_run_id] = []
    end
    push!(index["by_simulation"][sim_run_id], entry)
    
    # Update timestamp
    index["last_updated"] = string(now())
    
    # Save index
    open(index_file, "w") do f
        JSON.print(f, index, 2)
    end
end

# ============================================================================
# PART 3: SAVING OBSERVABLE DATA
# ============================================================================

"""
    _save_observable_sweep(obs_value, obs_run_dir, sweep; extra_data=Dict())

Save observable value for a single sweep.

Called once per sweep during observable calculation.

# Arguments
- `obs_value`: Observable value (can be scalar, vector, etc.)
- `obs_run_dir::String`: Path to observable run directory
- `sweep::Int`: Sweep number
- `extra_data::Dict`: Optional metadata (from original simulation)

# Side Effects
1. Saves observable_sweep_N.jld2 file
2. Updates metadata.json with sweep info

# Example
```julia
# In calculation loop
for sweep in sweeps_to_process
    obs_value = calculate_observable(...)
    _save_observable_sweep(obs_value, obs_run_dir, sweep; 
                         extra_data=Dict("time" => current_time))
end
```
"""
function _save_observable_sweep(obs_value, 
                              obs_run_dir::String, 
                              sweep::Int; 
                              extra_data::Dict=Dict())
    # ════════════════════════════════════════════════════════════════════════
    # 1. Save observable value to binary file
    # ════════════════════════════════════════════════════════════════════════
    
    filename = @sprintf("observable_sweep_%d.jld2", sweep)
    filepath = joinpath(obs_run_dir, filename)
    
    jldsave(filepath;
            observable_value=obs_value,
            sweep=sweep,
            extra_data=extra_data)  # Original simulation metadata
    
    # ════════════════════════════════════════════════════════════════════════
    # 2. Update metadata.json
    # ════════════════════════════════════════════════════════════════════════
    
    metadata_path = joinpath(obs_run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    # Update progress
    metadata["sweeps_processed"] = metadata["sweeps_processed"] + 1
    metadata["last_update"] = string(now())
    
    # Add sweep entry
    sweep_info = Dict(
        "sweep" => sweep,
        "filename" => filename,
        "observable_value" => obs_value  # Store for quick access
    )
    
    # Merge with extra_data if available
    if !isempty(extra_data)
        sweep_info = merge(sweep_info, extra_data)
    end
    
    push!(metadata["sweep_data"], sweep_info)
    
    # Save updated metadata
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
end

"""
    _finalize_observable_run(obs_run_dir; status="completed")

Mark observable calculation as completed or failed.

# Arguments
- `obs_run_dir::String`: Path to observable run directory
- `status::String`: Final status ("completed" or "failed")
"""
function _finalize_observable_run(obs_run_dir::String; status::String="completed")
    metadata_path = joinpath(obs_run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    # Update final status
    metadata["status"] = status
    metadata["end_time"] = string(now())
    
    # Save
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
    
    println("  ✓ Observable calculation finalized with status: $status")
end

# ============================================================================
# PART 4: LOADING OBSERVABLE DATA
# ============================================================================

"""
    load_observable_sweep(obs_run_dir, sweep) -> (observable_value, extra_data)

Load observable value for a specific sweep.

# Arguments
- `obs_run_dir::String`: Path to observable run directory
- `sweep::Int`: Sweep number

# Returns
- `(observable_value, extra_data)`: Observable value and metadata
"""
function load_observable_sweep(obs_run_dir::String, sweep::Int)
    filename = @sprintf("observable_sweep_%d.jld2", sweep)
    filepath = joinpath(obs_run_dir, filename)
    
    if !isfile(filepath)
        error("Observable file not found: $filepath\n" *
              "Sweep $sweep may not have been calculated.")
    end
    
    data = load(filepath)
    
    return data["observable_value"], data["extra_data"]
end

"""
    load_all_observable_results(obs_run_dir) -> Vector

Load all observable results from a calculation run.

# Returns
- Vector of (sweep, observable_value) tuples sorted by sweep number
"""
function load_all_observable_results(obs_run_dir::String)
    metadata_path = joinpath(obs_run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    results = []
    for sweep_info in metadata["sweep_data"]
        sweep = sweep_info["sweep"]
        obs_value, _ = load_observable_sweep(obs_run_dir, sweep)
        push!(results, (sweep, obs_value))
    end
    
    # Sort by sweep number
    sort!(results, by=x -> x[1])
    
    return results
end

# ============================================================================
# PART 5: QUERY FUNCTIONS
# ============================================================================

"""
    find_observables_for_simulation(sim_run_id; obs_base_dir="observables") -> Vector

Find all observable calculations for a given simulation run.

# Arguments
- `sim_run_id::String`: Simulation run identifier
- `obs_base_dir::String`: Observable base directory

# Returns
- Vector of observable calculation entries (empty if none found)

# Example
```julia
obs_calcs = find_observables_for_simulation("20241103_142530_a3f5b2c1")
for obs in obs_calcs
    println("Observable: ", obs["observable_type"])
    println("  Run ID: ", obs["obs_run_id"])
    println("  Directory: ", obs["obs_run_dir"])
end
```
"""
function find_observables_for_simulation(sim_run_id::String; 
                                        obs_base_dir::String="observables")
    index_file = joinpath(obs_base_dir, "observables_index.json")
    
    if !isfile(index_file)
        return []  # No observables calculated yet
    end
    
    index = JSON.parsefile(index_file)
    
    # Lookup by sim_run_id
    if haskey(index["by_simulation"], sim_run_id)
        return index["by_simulation"][sim_run_id]
    else
        return []  # No observables for this simulation
    end
end

"""
    observable_already_calculated(obs_config, sim_run_id; obs_base_dir="observables") -> Bool

Check if an observable with this exact config has already been calculated.

Uses config hash to detect duplicates.
"""
function observable_already_calculated(obs_config::Dict, 
                                      sim_run_id::String; 
                                      obs_base_dir::String="observables")
    obs_hash = _compute_observable_config_hash(obs_config)
    observables = find_observables_for_simulation(sim_run_id, obs_base_dir=obs_base_dir)
    
    for obs in observables
        if obs["obs_config_hash"] == obs_hash
            return true
        end
    end
    
    return false
end

# ============================================================================
# PART 6: QUERY OBSERVABLES BY CONFIG (Mirrors simulation database pattern)
# ============================================================================

"""
    find_observable_runs_by_config(obs_config::Dict; base_dir="data", obs_base_dir="observables")
        -> Vector{Dict}

Find all observable calculation runs matching this exact config.

Mirrors `find_runs_by_config()` from simulation database.

# Returns
- Vector of observable run info (empty if none found)

# Example
```julia
obs_config = JSON.parsefile("configs/obs_magnetization.json")
runs = find_observable_runs_by_config(obs_config)

for run in runs
    println("Run: ", run["obs_run_id"])
    println("Dir: ", run["obs_run_dir"])
end
```
"""
function find_observable_runs_by_config(obs_config::Dict; 
                                        base_dir::String="data",
                                        obs_base_dir::String="observables")
    # Get simulation config and find simulation run
    sim_config_file = obs_config["simulation"]["config_file"]
    
    if !isfile(sim_config_file)
        error("Simulation config file not found: $sim_config_file")
    end
    
    sim_config = JSON.parsefile(sim_config_file)
    sim_runs = _find_runs_by_config(sim_config, base_dir)
    
    if isempty(sim_runs)
        return []  # No simulation data exists
    end
    
    # Get latest simulation run
    sim_run_id = sim_runs[end]["run_id"]
    
    # Find all observables for this simulation
    all_obs = find_observables_for_simulation(sim_run_id, obs_base_dir=obs_base_dir)
    
    # Filter by matching config hash
    obs_hash = _compute_observable_config_hash(obs_config)
    matching_runs = filter(obs -> obs["obs_config_hash"] == obs_hash, all_obs)
    
    return matching_runs
end

"""
    get_latest_observable_run_for_config(obs_config::Dict; base_dir="data", obs_base_dir="observables")
        -> Dict or nothing

Get the most recent observable calculation matching this config.

Mirrors `get_latest_run_for_config()` from simulation database.

# Returns
- Dict with observable run info, or nothing if not found

# Example
```julia
obs_config = JSON.parsefile("configs/obs_magnetization.json")
run_info = get_latest_observable_run_for_config(obs_config)

if run_info !== nothing
    obs_run_dir = run_info["obs_run_dir"]
    results = load_all_observable_results(obs_run_dir)
else
    println("Observable not yet calculated")
end
```
"""
function get_latest_observable_run_for_config(obs_config::Dict;
                                             base_dir::String="data",
                                             obs_base_dir::String="observables")
    runs = find_observable_runs_by_config(obs_config, base_dir=base_dir, obs_base_dir=obs_base_dir)
    
    if isempty(runs)
        return nothing
    end
    
    # Sort by timestamp (most recent first)
    sorted_runs = sort(runs, by=r -> r["timestamp"], rev=true)
    
    return sorted_runs[1]
end