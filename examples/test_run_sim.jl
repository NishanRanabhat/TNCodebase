using Revise
using JSON
using BenchmarkTools

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "src", "TNCodebase.jl"))

using .TNCodebase

config = JSON.parsefile("configs/sim_tdvp.json")  # Returns Dict directly!

#run simulation
#run_simulation_from_config(config)

#access data
latest = get_latest_run_for_config(config, base_dir="data")
run_dir = latest["run_dir"]
#mps,extra_data = load_mps_sweep(run_dir,200)
mps, extra_data, closest_time = load_mps_at_time(run_dir,time=2.029)
println(extra_data)
#println(size(mps))
println(typeof(mps.tensors))