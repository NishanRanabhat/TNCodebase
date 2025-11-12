using Revise
using JSON3

push!(LOAD_PATH, joinpath(@__DIR__, "..", "src"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "src", "TNCodebase.jl"))

using .TNCodebase

# Test 1: Spin Polarized
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

println(single_site_expectation(10,X,psi))
println(single_site_expectation(10,Y,psi))
println(single_site_expectation(10,Z,psi))

println(subsystem_expectation_sum(X, psi,5,15))
println(subsystem_expectation_sum(Y, psi,5,15))
println(subsystem_expectation_sum(Z, psi,5,15))

# Test 2: Spin Neel
#println("Test 2: Spin Neel")
#config2 = JSON3.read(read("configs/state_configs/state_neel.json", String))
#psi2 = build_mps_from_config(config2)
#println("✓ Built spin polarized: $(length(psi2.tensors)) sites, shape $(size(psi2.tensors[1]))\n")

# Test 3: Spin Kink
#println("Test 3: Spin Kink")
#config3 = JSON3.read(read("configs/state_configs/state_kink.json", String))
#psi3 = build_mps_from_config(config3)
#println("✓ Built spin polarized: $(length(psi3.tensors)) sites, shape $(size(psi3.tensors[1]))\n")

# Test 4: Spin domain
#println("Test 4: Spin domain")
#config4 = JSON3.read(read("configs/state_configs/state_domain.json", String))
#psi4 = build_mps_from_config(config4)
#println("✓ Built spin polarized: $(length(psi4.tensors)) sites, shape $(size(psi4.tensors[1]))\n")

# Test 5: Spin custom
#println("Test 5: Spin custom")
#config5 = JSON3.read(read("configs/state_configs/state_spin_custom.json", String))
#psi5 = build_mps_from_config(config5)
#println("✓ Built spin polarized: $(length(psi5.tensors)) sites, shape $(size(psi5.tensors[1]))\n")

# Test 5: Spin Boson domain
#println("Test 5: Spin Boson domain")
#config5 = JSON3.read(read("configs/state_configs/state_spin_boson_domain.json", String))
#psi5 = build_mps_from_config(config5)
#println("✓ Built spin polarized: $(length(psi5.tensors)) sites, shape $(size(psi5.tensors[1]))\n")

# Test 5: Spin Boson Custom
#println("Test 5: Spin Boson custom")
#config5 = JSON3.read(read("configs/state_configs/state_spin_boson_custom.json", String))
#psi5 = build_mps_from_config(config5)
#println("✓ Built spin polarized: $(length(psi5.tensors)) sites, shape $(size(psi5.tensors[1]))\n")

# Test 5: Spin Boson Custom
#println("Test 5: Spin Boson custom")
#config5 = JSON3.read(read("configs/state_configs/state_spin_boson_custom.json", String))
#psi5 = build_mps_from_config(config5)
#println("✓ Built spin polarized: $(length(psi5.tensors)) sites, shape $(size(psi5.tensors[1]))\n")

# Test 5: Spin Boson random
#println("Test 5: Spin Boson random")
#config5 = JSON3.read(read("configs/state_configs/state_spin_boson_random.json", String))
#psi5 = build_mps_from_config(config5)
#println("✓ Built spin polarized: $(length(psi5.tensors)) sites, shape $(size(psi5.tensors[1]))\n")
