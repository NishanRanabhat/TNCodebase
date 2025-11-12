using Revise
using JSON
using BenchmarkTools

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "src", "TNCodebase.jl"))

using .TNCodebase

#access data
config = JSON.parsefile("configs/sim_tdvp.json")  # build config
latest = get_latest_run_for_config(config, base_dir="data")
run_dir = latest["run_dir"]
mps, extra_data, closest_time = load_mps_at_time(run_dir,time=0.00) #extract state
psi = mps.tensors

#println(inner_product(psi)) pass 

# Test expectations: Spin Polarized
println("Test 1: Spin Polarized")
config1 = JSON3.read(read("configs/state_configs/state_polarized.json", String))
psi = build_mps_from_config(config1).tensors
#println("✓ Built spin polarized: $(length(psi1.tensors)) sites, shape $(size(psi1.tensors[1]))\n")

X = [0 1;
      1 0]

Y = [0 -im;
      im  0]

Z = [1  0;
      0 -1]

I2 = [1 0;
      0 1]

#println(single_site_expectation(10,X,psi)) pass
#println(single_site_expectation(10,Y,psi)) pass
#println(single_site_expectation(10,Z,psi)) pass

#println(subsystem_expectation_sum(X, psi,5,15)) pass
#println(subsystem_expectation_sum(Y, psi,5,15)) pass
#println(subsystem_expectation_sum(Z, psi,5,15)) pass


