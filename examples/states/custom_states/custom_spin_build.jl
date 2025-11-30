#!/usr/bin/env julia
#
# Custom Spin Patterns Example

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Custom Spin Patterns")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "custom_spin_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: $(config["system"]["N"]) spins")
println("  State type: $(config["state"]["type"])")
println("  Pattern: Site-by-site specification")

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
for i in 1:length(mps.tensors)
    dims = size(mps.tensors[i])
    println("  Site $i: [$(dims[1]) × $(dims[2]) × $(dims[3])]")
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
println("Custom Pattern (as specified):")
println("─"^70)
pattern = config["state"]["spin_label"]
for (i, label) in enumerate(pattern)
    direction = label[1]
    eigenstate = label[2]
    println("  Site $i: ($direction, $eigenstate)")
end

println("\n" * "="^70)
println("Product state with custom site-by-site specification")
println("Bond dimension χ = 1")
println("="^70)
