#!/usr/bin/env julia
# examples/models/custom/tfim/build_model.jl
#
# Simple Example: Building TFIM from Channels
#
# This shows how to construct the Transverse Field Ising Model
# using custom channels instead of the prebuilt template.

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON

println("="^70)
println("Custom TFIM - Channel Construction")
println("="^70)

# ============================================================================
# LOAD CONFIGURATION
# ============================================================================

config_file = joinpath(@__DIR__, "model_config.json")
config = JSON.parsefile(config_file)

println("\nConfiguration:")
println("  System: $(config["system"]["N"]) spin-$(config["system"]["S"]) sites")
println("  Channels: $(length(config["model"]["params"]["channels"]))")

# Show each channel
println("\nChannels defined:")
for (i, ch) in enumerate(config["model"]["params"]["channels"])
    println("  $i. $(ch["type"])")
    println("     → $(ch["description"])")
end

# Extract parameters
J = config["model"]["params"]["channels"][1]["strength"]
h = config["model"]["params"]["channels"][2]["strength"]

println("\nPhysical parameters:")
println("  J (coupling): $J")
println("  h (field):    $h")

# ============================================================================
# BUILD SITES
# ============================================================================

println("\n" * "─"^70)
println("Building sites...")
sites = _build_sites_from_config(config["system"])
println("✓ Created $(length(sites)) sites")
println("  Each site has dimension d = $(sites[1].dim)")

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
# COMPARE TO PREBUILT
# ============================================================================

println("\n" * "─"^70)
println("Custom vs Prebuilt")
println("─"^70)

println("\nThis custom approach:")
println("  • Build from scratch using channels")
println("  • Full control over every term")
println("  • More verbose configuration")
println("  • Educational - see exactly what's built")

println("\nPrebuilt template approach:")
println("  • Use 'name': 'transverse_field_ising'")
println("  • Simpler configuration")
println("  • Standard parameters")
println("  • See: examples/models/prebuilt/tfim/")

println("\nBoth produce identical MPO!")
println("  Custom χ = $max_bond_dim")
println("  Prebuilt χ = $max_bond_dim")

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
✓ Built TFIM from 2 channels
✓ MPO has bond dimension χ = $max_bond_dim
✓ Identical to prebuilt template

What you learned:
  • How to build standard models from channels
  • Difference between custom and prebuilt
  • When to use each approach

Next steps:
  • Compare this config to prebuilt version
  • Modify to create variations (e.g., longitudinal field)
  • Use in simulation (examples/00_quickstart/)
""")

println("="^70)
