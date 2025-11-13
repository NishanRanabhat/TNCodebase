using Revise
using JSON
using BenchmarkTools

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "src", "TNCodebase.jl"))

using .TNCodebase

# 1. Load the observable config
obs_config = JSON.parsefile("configs/config_observable.json")

# 2. Run the calculation
results = run_observable_calculation_from_config(obs_config)

# 3. Access the results
println("\nResults:")
for (sweep, obs_value, extra_data) in results["results"]
    println("Sweep $sweep: ⟨Sz⟩ = $obs_value")
end

# Or get specific info
println("\nSimulation run ID: ", results["sim_run_id"])
println("Observable type: ", results["observable_type"])
println("Number of sweeps: ", length(results["results"]))

