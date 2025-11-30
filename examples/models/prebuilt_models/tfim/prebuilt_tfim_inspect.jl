#!/usr/bin/env julia
# examples/models/prebuilt/tfim/inspect_model.jl
#
# Prebuilt TFIM Template - Simple inspection

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..",".."))

using TNCodebase
using JSON

println("="^70)
println("Prebuilt TFIM Template")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "model_config.json")
config = JSON.parsefile(config_file)

println("\nTemplate: $(config["model"]["name"])")

# Show parameters
params = config["model"]["params"]
println("\nParameters:")
println("  J (coupling):    $(params["J"])")
println("  h (field):       $(params["h"])")
println("  Coupling dir:    $(params["coupling_dir"])")
println("  Field dir:       $(params["field_dir"])")

# Build sites and MPO
println("\n" * "─"^70)
sites = _build_sites_from_config(config["system"])
println("✓ Built $(length(sites)) sites")

mpo = build_mpo_from_config(config)
println("✓ Built MPO from template")

# Show MPO structure
bond_dims = [size(W, 4) for W in mpo.tensors[1:end-1]]
max_bond_dim = maximum(bond_dims)

println("\nMPO Structure:")
println("  Bond dimensions: ", bond_dims)
println("  Maximum χ = $max_bond_dim")

# Memory
total_elements = sum(length(W) for W in mpo.tensors)
memory_kb = total_elements * sizeof(Float64) / 1024
println("  Memory: $(round(memory_kb, digits=2)) KB")

println("\n" * "="^70)
println("Template automatically created 2 channels:")
println("  1. FiniteRangeCoupling(Z, Z, range=1, strength=$(params["J"]))")
println("  2. Field(X, strength=$(params["h"]))")
println("="^70)
