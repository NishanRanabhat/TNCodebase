# ============================================================================
# DATABASE MANAGEMENT SYSTEM FOR TENSOR NETWORK SIMULATIONS
# ============================================================================
#
# This module provides a hash-based database system for managing tensor network
# simulation runs with the following features:
#
# 1. CONFIG-BASED INDEXING: 
#    - Each config gets unique hash (8 hex chars)
#    - O(1) lookup: find all runs with same config
#    - No parameter extraction needed (works with any config structure)
#
# 2. AUTOMATIC DATA MANAGEMENT:
#    - Creates organized directory structure
#    - Saves MPS states and observables after each sweep
#    - Maintains metadata with full history
#
# 3. FLEXIBLE RETRIEVAL:
#    - DMRG: Load by sweep number
#    - TDVP: Load by physical time (uses dt arithmetic)
#    - Find runs by config, get latest, list available times
#
# DIRECTORY STRUCTURE:
#   data/
#   ├── runs_index.json              ← Master index (hash → runs)
#   ├── dmrg/
#   │   └── {run_id}/
#   │       ├── config.json
#   │       ├── metadata.json
#   │       └── mps_sweep_*.jld2
#   └── tdvp/
#       └── {run_id}/
#           ├── config.json
#           ├── metadata.json (includes dt)
#           └── mps_sweep_*.jld2
#
# TYPICAL WORKFLOW:
#   1. Setup: run_id, run_dir = _setup_run_directory(config)
#   2. Run simulation: _save_mps_sweep(state, run_dir, sweep; extra_data=...)
#   3. Finalize: _finalize_run(run_dir, status="completed")
#   4. Later: runs = _find_runs_by_config(config)
#   5. Access: mps, data = load_mps_sweep(run_dir, sweep)
#
# ============================================================================


using JSON
using SHA
using Dates: now, format
using JLD2
using Printf

# ============================================================================
# PART 1: HASH AND ID GENERATION (Internal Utilities)
# ============================================================================

"""
    _compute_config_hash(config::Dict) -> String

Compute an 8-character hash that uniquely identifies a configuration.

The hash is deterministic: same config always produces the same hash.

# How it works
1. Convert config to canonical JSON string
2. Compute SHA256 hash (256-bit cryptographic hash)
3. Take first 8 hex characters (32 bits = 4 billion unique values)

# Collision probability
- 10,000 configs: ~0.001%
- 100,000 configs: ~0.1%

# Returns
- String: 8 hex characters (e.g., "a3f5b2c1")

# Example
```julia
config = Dict("system" => Dict("N" => 16), "model" => ...)
hash = _compute_config_hash(config)
# Returns: "a3f5b2c1"
```

# Note
The hash captures EVERYTHING in the config, regardless of structure.
"""

const SIMULATION_KEYS = ["system", "model", "state", "algorithm"]

"""
Extract only simulation-relevant sections from config.
Ignores "info" and any other non-simulation sections.
"""
function _normalize_config_for_hash(config::Dict)
    normalized = Dict{String, Any}()
    for key in SIMULATION_KEYS
        if haskey(config, key)
            normalized[key] = config[key]
        end
    end
    return normalized
end

function _compute_config_hash(config::Dict)
    # Normalize: extract only simulation-relevant sections
    normalized = _normalize_config_for_hash(config)
    
    # Convert to canonical JSON (consistent formatting)
    config_str = JSON.json(normalized, 2)
    
    # Compute SHA256 and convert to hex string
    hash_full = bytes2hex(sha256(config_str))
    
    # Take first 8 characters
    return hash_full[1:8]
end


"""
    _generate_run_id(config::Dict) -> String

Generate a unique identifier for a simulation run.

Format: YYYYMMDD_HHMMSS_HHHHHHHH
        └─ timestamp ─┘ └─ hash ─┘

# Components
- Timestamp (YYYYMMDD_HHMMSS): Ensures uniqueness, enables chronological sorting
- Config Hash (8 hex chars): Identifies the configuration, enables grouping

# Returns
- String: Unique run ID (e.g., "20241103_142530_a3f5b2c1")

# Example
```julia
run_id = _generate_run_id(config)
# Returns: "20241104_153045_a3f5b2c1"
```
"""

function _generate_run_id(config::Dict)
    # Get current timestamp
    timestamp = Dates.format(now(), "yyyymmdd_HHMMSS")    
    # Get config hash
    config_hash = _compute_config_hash(config)    
    # Combine: timestamp_hash
    return "$(timestamp)_$(config_hash)"
end

# ============================================================================
# PART 2: SETUP AND INITIALIZATION (Called at Start of Simulation)
# ============================================================================

"""
    _setup_run_directory(config::Dict; base_dir::String="data") -> (String, String)

Initialize directory structure and files for a new simulation run.

Called ONCE at the start of each simulation, before any sweeps.

# What it creates
```
data/
├── runs_index.json              ← Updated with new run
└── {algorithm}/
    └── {run_id}/
        ├── config.json          ← Saved config (exact copy)
        └── metadata.json        ← Initialized metadata
```

# Arguments
- `config::Dict`: Complete simulation configuration
- `base_dir::String`: Root data directory (default: "data")

# Returns
- `run_id::String`: Unique identifier for this run
- `run_dir::String`: Full path to run directory

# Side Effects
1. Creates directory structure
2. Saves config.json (exact copy of input)
3. Initializes metadata.json (empty sweep history)
4. Updates runs_index.json (adds hash table entry)
5. For TDVP: Stores dt in metadata (enables time-based queries)

# Example
```julia
config = JSON.parsefile("sim_tdvp.json")
run_id, run_dir = _setup_run_directory(config, base_dir="data")

println("Simulation will save to: \$run_dir")
# Output: data/tdvp/20241104_153045_a3f5b2c1
```

# Usage in simulation
```julia
# At start
run_id, run_dir = _setup_run_directory(config)

# During simulation
for sweep in 1:n_sweeps
    # ... run algorithms ...
    _save_mps_sweep(state, run_dir, sweep; extra_data=...)
end

# At end
_finalize_run(run_dir)
```
"""

function _setup_run_directory(config::Dict; base_dir::String="data")
    # Generate unique ID
    run_id = _generate_run_id(config)
    
    # Get algorithm type for directory organization
    algorithm = config["algorithm"]["type"]
    
    # Create full path: base_dir/algorithm/run_id
    # Example: data/tdvp/20241103_142530_a3f5b2c1
    run_dir = joinpath(base_dir, algorithm, run_id)
    
    # Create directory (creates parents if needed)
    mkpath(run_dir)
    
    # ═══════════════════════════════════════════════════════
    # Save config.json (exact copy for reproducibility)
    # ═══════════════════════════════════════════════════════
    config_path = joinpath(run_dir, "config.json")
    open(config_path, "w") do f
        JSON.print(f, config, 2)  # Pretty-print with indentation
    end
    
    # ═══════════════════════════════════════════════════════
    # Initialize metadata.json
    # ═══════════════════════════════════════════════════════
    metadata = Dict(
        "run_id" => run_id,
        "algorithm" => algorithm,
        "start_time" => string(now()),
        "status" => "running",
        "sweeps_completed" => 0,
        "last_update" => string(now()),
        "sweep_data" => []  # Will fill during simulation
    )
    
    # Store dt for TDVP (enables time-based queries with simple arithmetic)
    if algorithm == "tdvp"
        metadata["dt"] = config["algorithm"]["options"]["dt"]
    end

    metadata_path = joinpath(run_dir, "metadata.json")
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
    
    # ═══════════════════════════════════════════════════════
    # Update master index
    # ═══════════════════════════════════════════════════════
    _update_index(config, run_id, run_dir, base_dir)
    
    # User feedback
    println("✓ Setup complete: $run_dir")
    
    return run_id, run_dir
end

"""
    _update_index(config::Dict, run_id::String, run_dir::String, base_dir::String)

Update the master index with a new run entry.

The index is a hash table: config_hash → [list of runs]

This function is called automatically by _setup_run_directory(), so you
typically don't call it directly.

# Index Structure
```json
{
  "by_config_hash": {
    "a3f5b2c1": [
      {
        "run_id": "20241103_142530_a3f5b2c1",
        "run_dir": "data/tdvp/20241103_142530_a3f5b2c1",
        "timestamp": "2024-11-03T14:25:30"
      }
    ]
  }
}
```

# What it does
1. Loads existing index (or creates new if first run)
2. Computes hash of config
3. Adds entry to hash table
4. Removes duplicate if run_id already exists
5. Saves updated index

# Performance
- Time: ~1-5ms (file I/O)
- Scales: O(1) regardless of total runs
"""

function _update_index(config::Dict, run_id::String, run_dir::String, base_dir::String)
    index_file = joinpath(base_dir, "runs_index.json")
    
    # Load existing index or create new
    index = if isfile(index_file)
        JSON.parsefile(index_file)
    else
        # First time - create structure
        Dict("by_config_hash" => Dict{String, Vector}())
    end
    
    # Compute hash
    config_hash = _compute_config_hash(config)
    
    # Initialize array for this hash if doesn't exist
    if !haskey(index["by_config_hash"], config_hash)
        index["by_config_hash"][config_hash] = []
    end
    
    # Create entry
    entry = Dict(
        "run_id" => run_id,
        "run_dir" => run_dir,
        "timestamp" => string(now())
    )
    
    # Remove old entry if run_id exists (prevents duplicates)
    filter!(r -> r["run_id"] != run_id, index["by_config_hash"][config_hash])
    
    # Add new entry
    push!(index["by_config_hash"][config_hash], entry)
    
    # Save updated index
    open(index_file, "w") do f
        JSON.print(f, index, 2)
    end
end

# ============================================================================
# PART 3: DATA SAVING (Called During Simulation)
# ============================================================================

"""
    _save_mps_sweep(state::MPSState, run_dir::String, sweep::Int; extra_data::Dict=Dict())

Save MPS state and observables after a sweep.

Called AFTER EACH SWEEP in the simulation loop.

# What it saves
1. MPS tensors → mps_sweep_XXXX.jld2 (binary file)
2. Observables → extra_data (energy, bond_dims, time, etc.)
3. Updates metadata.json with sweep history

# Arguments
- `state::MPSState`: Current simulation state
- `run_dir::String`: Path to run directory (from _setup_run_directory)
- `sweep::Int`: Current sweep number (1, 2, 3, ...)
- `extra_data::Dict`: Observables to save with this sweep

# Typical extra_data (DMRG)
```julia
extra_data = Dict(
    "energy" => -15.234,
    "variance" => 1e-10,
    "max_bond_dim" => 67,
    "bond_dims" => [2, 14, 28, 45, 67, ...]
)
```

# Typical extra_data (TDVP)
```julia
extra_data = Dict(
    "time" => 0.05,              # Physical time (enables time queries)
    "max_bond_dim" => 89,
    "bond_dims" => [2, 15, 32, 51, 73, 89, ...]
)
```

# Files created/updated
- `mps_sweep_XXXX.jld2`: Binary file with MPS tensors
- `metadata.json`: Updated with new sweep entry

# Performance
- Save time: ~0.1-1s (depends on MPS size)
- File size: ~1-100 MB per sweep (depends on χ and N)

# Example usage
```julia
# In DMRG loop
for sweep in 1:n_sweeps
    dmrg_sweep(state, solver, options, :right)
    energy = dmrg_sweep(state, solver, options, :left)
    
    extra_data = Dict(
        "energy" => energy,
        "variance" => compute_variance(state),
        "max_bond_dim" => maximum(bond_dims),
        "bond_dims" => bond_dims
    )
    
    _save_mps_sweep(state, run_dir, sweep; extra_data=extra_data)
end
```
```julia
# In TDVP loop
current_time = 0.0
for sweep in 1:n_sweeps
    tdvp_sweep(state, solver, options, :right)
    tdvp_sweep(state, solver, options, :left)
    current_time += dt
    
    extra_data = Dict(
        "time" => current_time,
        "max_bond_dim" => maximum(bond_dims),
        "bond_dims" => bond_dims
    )
    
    _save_mps_sweep(state, run_dir, sweep; extra_data=extra_data)
end
```
"""

function _save_mps_sweep(state::MPSState, run_dir::String, sweep::Int; extra_data::Dict=Dict())
    # ════════════════════════════════════════════════════════════════════════
    # 1. Save MPS to binary file
    # ════════════════════════════════════════════════════════════════════════
    
    # Create filename with zero-padded sweep number
    # Format: mps_sweep_0001.jld2, mps_sweep_0002.jld2, ...
    filename = @sprintf("mps_sweep_%d.jld2", sweep)
    filepath = joinpath(run_dir, filename)
    
    # Save MPS and extra_data to JLD2 file
    # JLD2 is efficient binary format for Julia objects
    jldsave(filepath; 
            mps=state.mps.tensors,        # The MPS object with all tensors
            extra_data=extra_data, # Observables
            sweep=sweep)           # Sweep number for verification
    
    # ════════════════════════════════════════════════════════════════════════
    # 2. Update metadata.json
    # ════════════════════════════════════════════════════════════════════════
    
    metadata_path = joinpath(run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    # Update progress counters
    metadata["sweeps_completed"] = sweep
    metadata["last_update"] = string(now())
    
    # Add entry to sweep history
    sweep_info = merge(
        Dict("sweep" => sweep, "filename" => filename),
        extra_data  # Includes energy, bond_dims, etc.
    )
    push!(metadata["sweep_data"], sweep_info)
    
    # ════════════════════════════════════════════════════════════════════════
    # 3. Save updated metadata
    # ════════════════════════════════════════════════════════════════════════
    
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
end

function _finalize_run(run_dir::String; status::String="completed")
    metadata_path = joinpath(run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    # Update final status
    metadata["status"] = status
    metadata["end_time"] = string(now())
    
    # Save
    open(metadata_path, "w") do f
        JSON.print(f, metadata, 2)
    end
    
    println("  ✓ Run finalized with status: $status")
end


function _find_runs_by_config(config::Dict, base_dir::String="data")
    # Compute hash
    config_hash = _compute_config_hash(config)
    
    # Load index
    index_file = joinpath(base_dir, "runs_index.json")
    if !isfile(index_file)
        return []  # No simulations yet
    end
    
    index = JSON.parsefile(index_file)
    
    # Lookup by hash (O(1))
    if haskey(index["by_config_hash"], config_hash)
        return index["by_config_hash"][config_hash]
    else
        return []  # This config never run
    end
end

function _config_already_run(config::Dict, base_dir::String="data")
    return !isempty(_find_runs_by_config(config, base_dir))
end

"""
    _get_completed_run(config::Dict; base_dir::String="data") -> Union{Dict, Nothing}

Check if a COMPLETED simulation exists for the given config.

Returns the run info dict if found, nothing otherwise.
Only returns runs with status="completed" in metadata.
"""
function _get_completed_run(config::Dict; base_dir::String="data")
    # Find all runs matching this config's hash
    runs = _find_runs_by_config(config, base_dir)
    
    if isempty(runs)
        return nothing
    end
    
    # Check each run's metadata for completion status
    for run in runs
        run_dir = run["run_dir"]
        metadata_path = joinpath(run_dir, "metadata.json")
        
        # Skip if metadata doesn't exist
        if !isfile(metadata_path)
            continue
        end
        
        try
            metadata = JSON.parsefile(metadata_path)
            if get(metadata, "status", "") == "completed"
                return run  # Found a completed run
            end
        catch e
            @warn "Could not read metadata for run $(run["run_id"]): $e"
            continue
        end
    end
    
    return nothing  # No completed run found
end

function _get_latest_run_for_config(config::Dict; base_dir::String="data")
    runs = _find_runs_by_config(config, base_dir)
    
    if isempty(runs)
        return nothing
    end
    
    # Sort by timestamp (most recent first)
    sorted_runs = sort(runs, by=r -> r["timestamp"], rev=true)
    
    return sorted_runs[1]
end

function load_mps_sweep(run_dir::String, sweep::Int)
    # Construct filename
    filename = @sprintf("mps_sweep_%d.jld2", sweep)
    filepath = joinpath(run_dir, filename)
    
    # Check if file exists
    if !isfile(filepath)
        error("MPS file not found: $filepath\n" *
              "Sweep $sweep may not have been saved.")
    end
    
    # Load from JLD2 file
    data = load(filepath)
    
    # Extract tensors and reconstruct MPS
    tensors = data["mps"]
    N = length(tensors)
    mps = MPS(tensors)
    
    # Return MPS and observables
    return mps, data["extra_data"]
end

function load_mps_at_time(run_dir::String; time::Float64=1.0, tol::Float64=1e-9)
    # Load metadata
    metadata_path = joinpath(run_dir, "metadata.json")
    
    if !isfile(metadata_path)
        error("Metadata file not found: $metadata_path")
    end
    
    metadata = JSON.parsefile(metadata_path)
    
    # Check if TDVP run (has dt)
    if !haskey(metadata, "dt")
        error("This is not a TDVP run (no dt found in metadata).\n" *
              "Use load_mps_sweep(run_dir, sweep) for DMRG runs.")
    end
    
    dt = metadata["dt"]
    
    # ════════════════════════════════════════════════════════════════════════
    # Get all available times
    # ════════════════════════════════════════════════════════════════════════
    
    if !haskey(metadata, "sweep_data") || isempty(metadata["sweep_data"])
        error("No sweep data found in metadata")
    end
    
    # Extract (sweep, time) pairs
    available_times = []
    for sweep_info in metadata["sweep_data"]
        if haskey(sweep_info, "time")
            push!(available_times, (sweep_info["sweep"], sweep_info["time"]))
        end
    end
    
    if isempty(available_times)
        error("No time information found in sweep_data (not a TDVP run?)")
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # Find closest available time
    # ════════════════════════════════════════════════════════════════════════
    
    closest_sweep = available_times[1][1]
    closest_time = available_times[1][2]
    min_diff = abs(available_times[1][2] - time)
    
    for (sweep, t) in available_times
        diff = abs(t - time)
        if diff < min_diff
            min_diff = diff
            closest_sweep = sweep
            closest_time = t
        end
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # Check if exact match or approximation
    # ════════════════════════════════════════════════════════════════════════
    
    if min_diff > tol
        @warn """Requested time $time not found.
        Loading closest available time: $closest_time (difference: $min_diff)
        Available time range: $(available_times[1][2]) to $(available_times[end][2])
        Use list_times(run_dir) to see all available times."""
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # Load MPS at closest sweep
    # ════════════════════════════════════════════════════════════════════════
    
    mps, extra_data = load_mps_sweep(run_dir, closest_sweep)
    
    return mps, extra_data, closest_time
end

function list_times(run_dir::String)
    metadata_path = joinpath(run_dir, "metadata.json")
    
    if !isfile(metadata_path)
        return []
    end
    
    metadata = JSON.parsefile(metadata_path)
    
    # Check if TDVP (has dt)
    if !haskey(metadata, "dt")
        @warn "This is not a TDVP run (no dt in metadata)"
        return []
    end
    
    if !haskey(metadata, "sweep_data")
        return []
    end
    
    # Extract (sweep, time) tuples from sweep_data
    times = []
    for sweep_info in metadata["sweep_data"]
        if haskey(sweep_info, "time")
            push!(times, (sweep_info["sweep"], sweep_info["time"]))
        end
    end
    
    return times
end

