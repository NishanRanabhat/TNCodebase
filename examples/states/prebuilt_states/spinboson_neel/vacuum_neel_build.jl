#!/usr/bin/env julia
# examples/states/prebuilt/spinboson/vacuum_neel/build_state.jl
#
# Prebuilt Spin-Boson Vacuum + Neel State Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Prebuilt Spin-Boson: Vacuum + Neel")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "vacuum_neel_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: 1 boson + $(config["system"]["N_spins"]) spins")
println("  Boson cutoff: nmax = $(config["system"]["nmax"])")
println("  Template: $(config["state"]["name"])")
println("  Boson level: $(config["state"]["params"]["boson_level"])")
println("  Spin direction: $(config["state"]["params"]["spin_direction"])")

# Build state
println("\n" * "─"^70)
println("Building MPS from template...")
mps = build_mps_from_config(config)
println("✓ MPS constructed")

# Inspect structure
println("\n" * "="^70)
println("MPS Structure")
println("="^70)

println("\nTensor dimensions [χ_left × d × χ_right]:")
dims_boson = size(mps.tensors[1])
println("  Site 1 (boson): [$(dims_boson[1]) × $(dims_boson[2]) × $(dims_boson[3])]")

for i in 2:min(6, length(mps.tensors))
    dims = size(mps.tensors[i])
    println("  Site $i (spin):  [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end
if length(mps.tensors) > 6
    println("  ...")
    dims = size(mps.tensors[end])
    println("  Site $(length(mps.tensors)) (spin):  [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end

# Bond dimensions
bond_dims = [size(A, 3) for A in mps.tensors[1:end-1]]
println("\nBond dimensions: ", bond_dims)

# Memory
total_elements = sum(length(A) for A in mps.tensors)
memory_bytes = total_elements * sizeof(Float64)
memory_kb = memory_bytes / 1024
println("Memory: $(round(memory_kb, digits=2)) KB")

# Show pattern
println("\n" * "─"^70)
println("State Pattern:")
println("─"^70)
boson_level = config["state"]["params"]["boson_level"]
direction = config["state"]["params"]["spin_direction"]
even_state = config["state"]["params"]["even_state"]
odd_state = config["state"]["params"]["odd_state"]

println("  Site 1: Boson in Fock state |$boson_level⟩")
for i in 2:min(9, config["system"]["N_spins"])
    spin_idx = i - 1
    state_val = (spin_idx % 2 == 1) ? odd_state : even_state
    site_type = (spin_idx % 2 == 1) ? "odd" : "even"
    println("  Site $i: Spin ($direction, $state_val)  [$site_type]")
end
if config["system"]["N_spins"] > 9
    println("  ...")
end

println("\n" * "="^70)
println("Heterogeneous product state: Boson + alternating spins")
println("Bond dimension χ = 1")
println("="^70)
