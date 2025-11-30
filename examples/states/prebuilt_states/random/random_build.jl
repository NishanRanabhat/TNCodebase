#!/usr/bin/env julia
# examples/states/prebuilt/random/build_state.jl
#
# Random MPS State Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON

println("="^70)
println("Random MPS State")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "random_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: $(config["system"]["N"]) spins")
println("  State type: $(config["state"]["type"])")
println("  Bond dimension: $(config["state"]["params"]["bond_dim"])")
println("  Data type: $(config["system"]["dtype"])")

# Build state
println("\n" * "─"^70)
println("Building random MPS...")
mps = build_mps_from_config(config)
println("✓ MPS constructed with random entries")

# Inspect structure
println("\n" * "="^70)
println("MPS Structure")
println("="^70)

χ = config["state"]["params"]["bond_dim"]

println("\nTensor dimensions [χ_left × d × χ_right]:")
dims_left = size(mps.tensors[1])
println("  Site 1 (left edge):  [$(dims_left[1]) × $(dims_left[2]) × $(dims_left[3])]")

for i in 2:min(4, length(mps.tensors)-1)
    dims = size(mps.tensors[i])
    println("  Site $i (bulk):       [$(dims[1]) × $(dims[2]) × $(dims[3])]")
end
if length(mps.tensors) > 5
    println("  ...")
end

dims_right = size(mps.tensors[end])
println("  Site $(length(mps.tensors)) (right edge): [$(dims_right[1]) × $(dims_right[2]) × $(dims_right[3])]")

# Bond dimensions
bond_dims = [size(A, 3) for A in mps.tensors[1:end-1]]
println("\nBond dimensions:")
println("  Left edge → bulk: $(bond_dims[1])")
println("  Bulk bonds: $(bond_dims[2:min(5, length(bond_dims)-1)])")
if length(bond_dims) > 6
    println("  ...")
end
println("  Bulk → right edge: $(bond_dims[end])")

# Memory
total_elements = sum(length(A) for A in mps.tensors)
memory_bytes = total_elements * sizeof(ComplexF64)
memory_kb = memory_bytes / 1024
println("\nMemory: $(round(memory_kb, digits=2)) KB")

println("\n" * "="^70)
println("Random MPS with entanglement")
println("All tensor entries randomly initialized")
println("Bond dimension χ = $χ throughout bulk")
println("="^70)
