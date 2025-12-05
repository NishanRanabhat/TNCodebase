#!/usr/bin/env julia
# examples/models/custom/xxz/build_model.jl
#
# Simple Example: Building XXZ Model from Channels
#
# This shows how to construct a custom model by specifying channels.
# The XXZ model has XX, YY, and ZZ couplings plus a field.

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON

println("="^70)
println("Custom XXZ Model - Channel Construction")
println("="^70)

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "heisenberg_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  Channels: $(length(config["model"]["params"]["channels"]))")

# Show each channel
println("\nChannels defined:")
for (i, ch) in enumerate(config["model"]["params"]["channels"])
    println("  $i. $(ch["type"])")
    println("     → $(ch["description"])")
end

# ============================================================================
# BUILD MPO
# ============================================================================

println("\n" * "─"^70)
println("Building MPO from channels...")
mpo = build_mpo_from_config(config)
println("✓ MPO constructed successfully")

# ============================================================================
# INSPECT MPO STRUCTURE
# ============================================================================

println("\n" * "="^70)
println("MPO Structure")
println("="^70)

# Show tensor dimensions
println("\nTensor dimensions [χ_left × d × d × χ_right]:")
for i in 1:min(5, length(mpo.tensors))
    dims = size(mpo.tensors[i])
    println("  Site $i: [$(dims[1]) × $(dims[2]) × $(dims[3]) × $(dims[4])]")
end
if length(mpo.tensors) > 5
    println("  ...")
    dims = size(mpo.tensors[end])
    println("  Site $(length(mpo.tensors)): [$(dims[1]) × $(dims[2]) × $(dims[3]) × $(dims[4])]")
end

# Bond dimensions
bond_dims = [size(W, 4) for W in mpo.tensors[1:end-1]]
max_bond_dim = maximum(bond_dims)

println("\nBond dimensions: ", bond_dims)
println("Maximum bond dimension: χ = $max_bond_dim")

# ============================================================================
# CHANNEL CONTRIBUTION TO BOND DIMENSION
# ============================================================================

println("\n" * "─"^70)
println("Understanding Bond Dimension")
println("─"^70)

println("\nHow channels contribute:")
println("  • Each nearest-neighbor coupling → adds ~1 to bond dim")
println("  • Each field term → adds ~1 to bond dim")
println("  • Total channels: $(length(config["model"]["params"]["channels"]))")
println("  • Expected χ ≈ $(length(config["model"]["params"]["channels"]) + 1)")
println("  • Actual χ = $max_bond_dim")

# ============================================================================
# MEMORY USAGE
# ============================================================================

total_elements = sum(length(W) for W in mpo.tensors)
memory_bytes = total_elements * sizeof(Float64)
memory_kb = memory_bytes / 1024

println("\n" * "─"^70)
println("Memory Usage")
println("─"^70)
println("  Total elements: $total_elements")
println("  Memory: $(round(memory_kb, digits=2)) KB")

# ============================================================================
# SUMMARY
# ============================================================================

println("\n" * "="^70)
println("Summary")
println("="^70)
println("""
✓ Built XXZ model from 4 channels
✓ MPO has bond dimension χ = $max_bond_dim
✓ Ready for DMRG or TDVP simulations

What you learned:
  • How to define channels in config
  • How channels combine into MPO
  • How bond dimension relates to channels

Next steps:
  • Modify channel strengths in config
  • Add more channels (e.g., next-nearest neighbor)
  • Use this MPO in DMRG (see examples/00_quickstart/)
""")

println("="^70)
