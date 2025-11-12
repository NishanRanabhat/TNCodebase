using Revise
using JSON3

push!(LOAD_PATH, joinpath(@__DIR__, "..", "newsrc"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "newsrc", "TNCodebase.jl"))

using .TNCodebase

println("="^70)
println("Testing Unified Channel-Based Interface")
println("="^70)

# Test 1: Pre-built TFIM
#println("\n--- Test 1: Pre-built TFIM ---")
#config1 = JSON3.read(read("configs/model_configs/model_tfim_prebuilt.json", String))
#println("Config: $(config1.model.name)")
#ham1 = build_mpo_from_config(config1)
#println("✓ Built MPO: $(length(ham1.tensors)) sites")
#println("  Element type: $(eltype(ham1.tensors[1]))")

# Test 1: Pre-built TFIM
println("\n--- Test 1: Pre-built TFIM ---")
config1 = JSON3.read(read("configs/model_configs/model_tfim_custom.json", String))
println("Config: $(config1.model.name)")

ham1 = build_mpo_from_config(config1)
println("✓ Built MPO: $(length(ham1.tensors)) sites")
println("  Element type: $(eltype(ham1.tensors[1]))")
println("  Element type: $(size(ham1.tensors[2]))")

for i in 1:3
    for j in 1:3
        println(ham1.tensors[2][i,j,:,:])
    end
end






