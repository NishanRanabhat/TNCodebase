#!/usr/bin/env julia
# examples/models/prebuilt/long_range_ising/inspect_model.jl
#
# Prebuilt Long-Range Ising Template - Simple inspection

using Pkg
Pkg.activate(joinpath(@__DIR__, "..", "..", "..", ".."))

using TNCodebase
using JSON

println("="^70)
println("Prebuilt Long-Range Ising Template")
println("="^70)

# Load configuration
config_file = joinpath(@__DIR__, "prebuilt_longrange_config.json")
config = JSON.parsefile(config_file)

println("\nTemplate: $(config["model"]["name"])")

# Show parameters
params = config["model"]["params"]
println("\nParameters:")
println("  J (coupling):    $(params["J"])")
println("  α (power-law):   $(params["alpha"])")
println("  K (exponentials): $(params["n_exp"])")
println("  h (field):       $(params["h"])")

mpo = build_mpo_from_config(config)
println("✓ Built MPO from template (FSM applied automatically)")

# Show MPO structure
bond_dims = [size(W, 2) for W in mpo.tensors[1:end-1]]
max_bond_dim = maximum(bond_dims)

println("\nMPO Structure:")
println("  Bond dimensions: ", bond_dims)
println("  Maximum χ = $max_bond_dim")

# Memory
total_elements = sum(length(W) for W in mpo.tensors)
memory_kb = total_elements * sizeof(Float64) / 1024
println("  Memory: $(round(memory_kb, digits=2)) KB")

# FSM efficiency
N = params["N"]
χ_naive = N
reduction = χ_naive / max_bond_dim

println("\n" * "─"^70)
println("FSM Efficiency:")
println("  χ_FSM = $max_bond_dim (this template)")
println("  χ_naive ≈ $χ_naive (without FSM)")
println("  Reduction: $(round(reduction, digits=1))×")

println("\n" * "="^70)
println("Template automatically created channels with FSM:")
println("  1. PowerLawCoupling(Z, Z, strength=$(params["J"]), α=$(params["alpha"]), K=$(params["n_exp"]))")
println("  2. Field(X, strength=$(params["h"]))")
println("="^70)
