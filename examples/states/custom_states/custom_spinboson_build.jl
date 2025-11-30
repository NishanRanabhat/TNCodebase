#!/usr/bin/env julia
#
# Custom Spin-Boson Patterns Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Custom Spin-Boson Patterns")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "custom_spinboson_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: 1 boson + $(config["system"]["N_spins"]) spins")
println("  Boson cutoff: nmax = $(config["system"]["nmax"])")
println("  State type: $(config["state"]["type"])")
println("  Boson level: $(config["state"]["boson_level"])")

# Build state
println("\n" * "─"^70)
println("Building MPS from custom pattern...")
mps = build_mps_from_config(config)
println("✓ MPS constructed")

# Inspect structure
println("\n" * "="^70)
println("MPS Structure")
println("="^70)

println("\nTensor dimensions [χ_left × d × χ_right]:")
dims_boson = size(mps.tensors[1])
println("  Site 1 (boson): [$(dims_boson[1]) × $(dims_boson[2]) × $(dims_boson[3])]")

for i in 2:length(mps.tensors)
    dims = size(mps.tensors[i])
    println("  Site $i (spin):  [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end

# Bond dimensions
bond_dims = [size(A, 3) for A in mps.tensors[1:end-1]]
println("\nBond dimensions: ", bond_dims)

# Memory
total_elements = sum(length(A) for A in mps.tensors)
memory_bytes = total_elements * sizeof(Float64)
memory_kb = memory_bytes / 1024
println("Memory: $(round(memory_kb, digits=2)) KB")

# Show custom pattern
println("\n" * "─"^70)
println("Custom Pattern:")
println("─"^70)
boson_level = config["state"]["boson_level"]
println("  Site 1: Boson in Fock state |$boson_level⟩")

spin_pattern = config["state"]["spin_label"]
for (i, label) in enumerate(spin_pattern)
    direction = label[1]
    eigenstate = label[2]
    site_idx = i + 1
    println("  Site $site_idx: Spin ($direction, $eigenstate)")
end

println("\n" * "="^70)
println("Heterogeneous product state: Custom boson + custom spins")
println("Bond dimension χ = 1")
println("="^70)
