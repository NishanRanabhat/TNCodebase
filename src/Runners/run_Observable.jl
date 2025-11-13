# ============================================================================
# OBSERVABLE CALCULATION RUNNER
# ============================================================================
#
# This module provides functionality for calculating observables on saved
# MPS data from tensor network simulations.
#
# RESPONSIBILITIES:
# - Load simulation config and find simulation data
# - Load MPS for specified sweeps
# - Calculate requested observables
# - Return results
#
# DATABASE/SAVING:
# - Handled separately in Database_observable_utils.jl (to be created)
#
# ============================================================================

using JSON
using JLD2
using LinearAlgebra

# ============================================================================
# PART 1: Operator Builders
# ============================================================================

"""
    build_operator_from_config(op_config) → Matrix

Convert operator specification to actual matrix.

# Arguments
- `op_config`: Either a string ("Sx", "Sy", "Sz", "Sp", "Sm") or a matrix

# Returns
- Matrix representation of the operator

# Example
```julia
Sz = build_operator_from_config("Sz")
custom_op = build_operator_from_config([[0.5, 0], [0, -0.5]])
```
"""
function build_operator_from_config(op_config)
    # If already a matrix, return it
    if op_config isa AbstractArray
        return op_config
    end
    
    # Otherwise, build from string
    if op_config == "Sz"
        return [0.5 0.0; 0.0 -0.5]
    elseif op_config == "Sx"
        return [0.0 0.5; 0.5 0.0]
    elseif op_config == "Sy"
        return [0.0 -0.5im; 0.5im 0.0]
    elseif op_config == "Sp"
        return [0.0 1.0; 0.0 0.0]
    elseif op_config == "Sm"
        return [0.0 0.0; 1.0 0.0]
    else
        error("Unknown operator: $op_config. Use 'Sx', 'Sy', 'Sz', 'Sp', 'Sm' or provide matrix")
    end
end

# ============================================================================
# PART 2: Sweep Selection
# ============================================================================

"""
    get_sweeps_to_process(sweep_config, run_dir) → Vector{Int}

Determine which sweeps to process based on sweep selection config.

# Arguments
- `sweep_config::Dict`: Sweep selection configuration
- `run_dir::String`: Path to simulation run directory

# Returns
- Vector of sweep numbers to process

# Sweep Selection Types
- "all": Process all available sweeps
- "range": Process sweeps in [start, end]
- "specific": Process specific list of sweeps
- "time_range": For TDVP, process sweeps in time range (converts to sweep numbers)

# Example
```json
{"selection": "all"}
{"selection": "range", "range": [1, 50]}
{"selection": "specific", "list": [1, 10, 20, 50]}
{"selection": "time_range", "time_range": [0.0, 1.0]}  // TDVP only
```
"""
function get_sweeps_to_process(sweep_config::Dict, run_dir::String)
    selection = sweep_config["selection"]
    
    # Load metadata to get available sweeps
    metadata_path = joinpath(run_dir, "metadata.json")
    metadata = JSON.parsefile(metadata_path)
    
    available_sweeps = [entry["sweep"] for entry in metadata["sweep_data"]]
    
    if selection == "all"
        return available_sweeps
        
    elseif selection == "range"
        start_sweep, end_sweep = sweep_config["range"]
        return filter(s -> start_sweep <= s <= end_sweep, available_sweeps)
        
    elseif selection == "specific"
        requested = sweep_config["list"]
        return filter(s -> s in requested, available_sweeps)
        
    elseif selection == "time_range"
        # Only for TDVP runs
        if !haskey(metadata, "dt")
            error("time_range selection only valid for TDVP runs")
        end
        
        t_start, t_end = sweep_config["time_range"]
        
        # Filter sweeps by time
        selected_sweeps = Int[]
        for entry in metadata["sweep_data"]
            if haskey(entry, "time")
                t = entry["time"]
                if t_start <= t <= t_end
                    push!(selected_sweeps, entry["sweep"])
                end
            end
        end
        
        return selected_sweeps
        
    else
        error("Unknown sweep selection: $selection. Use 'all', 'range', 'specific', or 'time_range'")
    end
end

# ============================================================================
# PART 3: Observable Calculation Dispatcher
# ============================================================================

"""
    calculate_observable(obs_type, params, mps, ham) → value

Dispatch to appropriate observable function based on type.

# Arguments
- `obs_type::String`: Observable type (matches function names in Analysis/)
- `params::Dict`: Observable-specific parameters
- `mps::Vector`: MPS tensors
- `ham::Vector`: Hamiltonian MPO (optional, only for energy observables)

# Returns
- Calculated observable value (type depends on observable)
"""
function calculate_observable(obs_type::String, params::Dict, mps::Vector{<:AbstractArray{T1,3}}, ham::Union{Vector{<:AbstractArray{T2,3}},Nothing}=nothing) where {T1,T2}
    
    if obs_type == "single_site_expectation"
        site = params["site"]
        operator = build_operator_from_config(params["operator"])
        return single_site_expectation(site, operator, mps)
        
    elseif obs_type == "subsystem_expectation_sum"
        operator = build_operator_from_config(params["operator"])
        l = params["l"]
        m = params["m"]
        return subsystem_expectation_sum(operator, mps, l, m)
        
    elseif obs_type == "two_site_expectation"
        site_i = params["site_i"]
        site_j = params["site_j"]
        op_i = build_operator_from_config(params["operator_i"])
        op_j = build_operator_from_config(params["operator_j"])
        return two_site_expectation(site_i, op_i, site_j, op_j, mps)
        
    elseif obs_type == "correlation_function"
        site_i = params["site_i"]
        site_j = params["site_j"]
        operator = build_operator_from_config(params["operator"])
        return correlation_function(site_i, site_j, operator, mps)
        
    elseif obs_type == "connected_correlation"
        site_i = params["site_i"]
        site_j = params["site_j"]
        operator = build_operator_from_config(params["operator"])
        return connected_correlation(site_i, site_j, operator, mps)
        
    elseif obs_type == "entanglement_spectrum"
        bond = params["bond"]
        n_values = get(params, "n_values", nothing)
        return entanglement_spectrum(bond, mps; n_values=n_values)
        
    elseif obs_type == "entanglement_entropy"
        bond = params["bond"]
        alpha = get(params, "alpha", 1)
        return entanglement_entropy(bond, mps; alpha=alpha)
        
    elseif obs_type == "energy_expectation"
        if ham === nothing
            error("energy_expectation requires Hamiltonian")
        end
        return energy_expectation(mps, ham)
        
    elseif obs_type == "energy_variance"
        if ham === nothing
            error("energy_variance requires Hamiltonian")
        end
        return energy_variance(mps, ham)
        
    else
        error("Unknown observable type: $obs_type")
    end
end

# ============================================================================
# PART 4: Main Observable Runner (Calculation Only)
# ============================================================================

"""
    run_observable_calculation_from_config(obs_config; base_dir="data") → Dict

Main entry point for observable calculations.

IMPORTANT: This function only CALCULATES observables, it does NOT save them.
Saving is handled separately by database functions.

# Arguments
- `obs_config::Dict`: Observable configuration
- `base_dir::String`: Base directory for simulation data (default: "data")

# Returns
- `Dict` with keys:
  - "sim_run_id": Simulation run identifier
  - "sim_run_dir": Path to simulation data
  - "observable_type": Type of observable calculated
  - "observable_params": Parameters used
  - "results": Vector of (sweep, observable_value, extra_data) tuples

# Workflow
1. Load simulation config from referenced file
2. Find simulation run using config hash
3. Determine sweeps to process
4. For each sweep:
   - Load MPS
   - Calculate observable
5. Return all results

# Example
```julia
obs_config = JSON.parsefile("obs_magnetization.json")
results = run_observable_calculation_from_config(obs_config)

# Access results
for (sweep, obs_value, extra_data) in results["results"]
    println("Sweep \$sweep: \$obs_value")
end

# Later: save using database functions
save_observable_results(results, obs_config)  # From Database_observable_utils.jl
```
"""
function run_observable_calculation_from_config(obs_config::Dict; base_dir::String="data")
    println("="^70)
    println("Starting Observable Calculation from Config")
    println("="^70)
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 1: Load Simulation Config and Find Run
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[1/4] Loading simulation config and finding run...")
    
    sim_config_file = obs_config["simulation"]["config_file"]
    
    if !isfile(sim_config_file)
        error("Simulation config file not found: $sim_config_file")
    end
    
    sim_config = JSON.parsefile(sim_config_file)
    println("  ✓ Loaded simulation config: $sim_config_file")
    
    # Find runs with this config
    runs = find_runs_by_config(sim_config, base_dir)
    
    if isempty(runs)
        error("No simulation data found for this config!\n" *
              "Run the simulation first with: run_simulation_from_config()")
    end
    
    # Select run (use latest if multiple)
    if length(runs) == 1
        run_info = runs[1]
        println("  ✓ Found simulation run: $(run_info["run_id"])")
    else
        run_info = get_latest_run_for_config(sim_config, base_dir=base_dir)
        println("  ⚠ Multiple runs found, using latest: $(run_info["run_id"])")
        println("    (Found $(length(runs)) runs total)")
    end
    
    sim_run_id = run_info["run_id"]
    sim_run_dir = run_info["run_dir"]
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 2: Determine Sweeps to Process
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[2/4] Determining sweeps to process...")
    
    sweeps_to_process = get_sweeps_to_process(obs_config["sweeps"], sim_run_dir)
    
    println("  ✓ Sweeps to process: $(length(sweeps_to_process))")
    println("    Range: $(minimum(sweeps_to_process)) to $(maximum(sweeps_to_process))")
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 3: Load Hamiltonian if Needed
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[3/4] Preparing observable calculation...")
    
    obs_type = obs_config["observable"]["type"]
    obs_params = obs_config["observable"]["params"]
    
    println("  Observable type: $obs_type")
    
    # Check if we need the Hamiltonian
    needs_ham = obs_type in ["energy_expectation", "energy_variance"]
    
    ham = nothing
    if needs_ham
        println("  Building Hamiltonian (needed for energy observables)...")
        ham_mpo = build_mpo_from_config(sim_config)
        ham = ham_mpo.tensors
        println("  ✓ Hamiltonian loaded")
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # STEP 4: Calculate Observables for Each Sweep
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[4/4] Calculating observables...")
    println("="^70)
    
    results = []
    
    for (idx, sweep) in enumerate(sweeps_to_process)
        # Load MPS for this sweep
        mps, extra_data = load_mps_sweep(sim_run_dir, sweep)
        
        # Calculate observable
        obs_value = calculate_observable(obs_type, obs_params, mps.tensors, ham)
        
        # Store result (sweep, value, extra_data)
        push!(results, (sweep, obs_value, extra_data))
        
        # Print progress
        if idx % max(1, div(length(sweeps_to_process), 10)) == 0
            println("  Progress: $idx/$(length(sweeps_to_process)) sweeps")
        end
    end
    
    # ════════════════════════════════════════════════════════════════════════
    # Return Results
    # ════════════════════════════════════════════════════════════════════════
    
    println("="^70)
    println("\n✓ Observable calculation complete!")
    println("  Calculated: $obs_type")
    println("  Sweeps processed: $(length(results))")
    println("\nNOTE: Results are in memory. Use database functions to save.")
    println("="^70)
    
    # Return structured results
    return Dict(
        "sim_run_id" => sim_run_id,
        "sim_run_dir" => sim_run_dir,
        "sim_config" => sim_config,
        "observable_type" => obs_type,
        "observable_params" => obs_params,
        "results" => results  # Vector of (sweep, observable_value, extra_data)
    )
end

# ============================================================================
# PART 5: Convenience Function for Quick Calculation
# ============================================================================

"""
    calculate_observable_at_sweep(obs_type, params, sim_run_dir, sweep; base_dir="data")

Calculate observable for a single sweep (utility function).

# Arguments
- `obs_type::String`: Observable type
- `params::Dict`: Observable parameters
- `sim_run_dir::String`: Path to simulation run directory
- `sweep::Int`: Sweep number

# Returns
- Observable value

# Example
```julia
obs_value = calculate_observable_at_sweep(
    "single_site_expectation",
    Dict("operator" => "Sz", "site" => 10),
    "data/tdvp/20241103_142530_a3f5b2c1",
    50
)
```
"""
function calculate_observable_at_sweep(obs_type::String, params::Dict, 
                                       sim_run_dir::String, sweep::Int)
    # Load MPS
    mps, extra_data = load_mps_sweep(sim_run_dir, sweep)
    
    # Load Hamiltonian if needed
    needs_ham = obs_type in ["energy_expectation", "energy_variance"]
    ham = nothing
    if needs_ham
        # Load simulation config to rebuild Hamiltonian
        sim_config = JSON.parsefile(joinpath(sim_run_dir, "config.json"))
        ham_mpo = build_mpo_from_config(sim_config)
        ham = ham_mpo.tensors
    end
    
    # Calculate and return
    return calculate_observable(obs_type, params, mps, ham)
end