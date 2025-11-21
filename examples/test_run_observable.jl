using Revise
using JSON
using BenchmarkTools

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))
includet(joinpath(@__DIR__, "..", "src", "TNCodebase.jl"))
using .TNCodebase

# 1. Load the observable config
obs_config = JSON.parsefile("configs/config_observable.json")

# 2. Run the calculation (CHANGED: now returns two values)
#obs_run_id, obs_run_dir = run_observable_calculation_from_config(obs_config)

# 3. Load the results from disk (NEW: data is saved, not returned)
#results = load_all_observable_results(obs_run_dir)

# 4. Access the results
#println("\nResults:")
#for (sweep, obs_value) in results  # Note: now just (sweep, value), no extra_data
#    println("Sweep $sweep: ⟨Sz⟩ = $obs_value")
#end

# 5. Get specific info
#println("\nObservable run ID: ", obs_run_id)
#println("Observable directory: ", obs_run_dir)
#println("Number of sweeps: ", length(results))

# Find runs
run_info = get_latest_observable_run_for_config(obs_config)

#print(run_info)

# Extract directory yourself
obs_run_dir = run_info["obs_run_dir"]

# Load manually
results = load_all_observable_results(obs_run_dir)

print(obs_run_dir)

# 4. Access the results
#println("\nResults:")
#for (sweep, obs_value) in results  # Note: now just (sweep, value), no extra_data
#    println("Sweep $sweep: ⟨Sy⟩ = $obs_value")
#end