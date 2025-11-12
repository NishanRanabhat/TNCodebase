# ============================================================================
# PART 1: System Builder - Construct site arrays
# ============================================================================

"""
Parse dtype string to Julia type
"""
function parse_dtype(dtype_str::String)
    dtype_map = Dict(
        "Float64" => Float64,
        "ComplexF64" => ComplexF64,
        "Float32" => Float32,
        "ComplexF32" => ComplexF32
    )
    haskey(dtype_map, dtype_str) || error("Unknown dtype: $dtype_str")
    return dtype_map[dtype_str]
end

"""
Build sites array from system configuration.
Handles both homogeneous (spin-only) and heterogeneous (spin-boson) systems.
"""
function build_sites_from_config(system_config)
    system_type = system_config["type"]
    dtype = parse_dtype(get(system_config, "dtype", "ComplexF64"))
    
    if system_type == "spin"
        return build_spin_system(system_config, dtype)
    elseif system_type == "spinboson"
        return build_spinboson_system(system_config, dtype)
    else
        error("Unknown system type: $system_type. Use 'spin' or 'spinboson'")
    end
end

"""
Build homogeneous spin system
"""
function build_spin_system(config, dtype)
    N = config["N"]
    S = get(config, "S", 0.5)  # Default spin-1/2
    
    spin_site = SpinSite(S, T=dtype)
    return fill(spin_site, N)
end

"""
Build spin-boson system: [BosonSite, SpinSite, SpinSite, ...]
"""
function build_spinboson_system(config, dtype)
    N_spins = config["N_spins"]
    nmax = config["nmax"]
    S = get(config, "S", 0.5)  # Default spin-1/2
    
    boson_site = BosonSite(nmax, T=dtype)
    spin_site = SpinSite(S, T=dtype)
    
    return vcat(boson_site, fill(spin_site, N_spins))
end

# ============================================================================
# PART 2: Prebuilt State Pattern Generators
# ============================================================================

# ───────────────────────────────────────────────────────────────────────────
# Spin-Only Prebuilt States, these are initializing labels
# ───────────────────────────────────────────────────────────────────────────

"""
All spins aligned in given direction and eigenstate
"""
function get_label_polarized(N::Int, direction::Symbol, eigenstate::Int)
    return fill((direction, eigenstate), N)
end

"""
Alternating spin configuration (Neel state)
"""
function get_label_neel(N::Int, direction::Symbol; 
                         even_state::Int=1, odd_state::Int=2)
    return [(direction, i % 2 == 1 ? odd_state : even_state) for i in 1:N]
end

"""
single kink: two regions with different polarizations
"""
function get_label_kink(N::Int, direction::Symbol; position::Int=Int(ceil(N/2)),
                                left_state::Int=1, right_state::Int=2)
    @assert 1 <= position < N "Position must be in range [1, N-1]"
    return [(direction, i <= position ? left_state : right_state) for i in 1:N]
end

"""
domain state: single or multiple spin flips at specified positions bounded by two kinks
"""
function get_label_domain(N::Int, direction::Symbol; 
                            start_index::Int=Int(ceil(N/2)),
                            domain_size::Int=Int(ceil(N/2)),
                            base_state::Int=1, 
                            flip_state::Int=2)
    @assert 1 <= start_index <= N "start_index out of range"

    pattern = fill((direction, base_state), N)
    end_index = min(start_index + domain_size - 1, N)  

    for pos in start_index:end_index
        pattern[pos] = (direction, flip_state)
    end
    return pattern
end

# ───────────────────────────────────────────────────────────────────────────
# Spin-Boson Prebuilt States
# ───────────────────────────────────────────────────────────────────────────

"""
Boson in specific Fock state + all spins polarized
"""
function get_label_spinboson_polarized(N_spins::Int, boson_level::Int,
                                        spin_direction::Symbol, spin_eigenstate::Int)
    spin_label = fill((spin_direction, spin_eigenstate), N_spins)
    return vcat(boson_level, spin_label)
end

"""
Boson in specific Fock state + Neel spin pattern
"""
function get_label_spinboson_neel(N_spins::Int, boson_level::Int,
                                    spin_direction::Symbol;
                                    even_state::Int=1, 
                                    odd_state::Int=2)
    spin_label = get_label_neel(N_spins, spin_direction, 
                                   even_state=even_state, 
                                   odd_state=odd_state)
    return vcat(boson_level, spin_label)
end

"""
Boson + spin domain wall
"""
function get_label_spinboson_kink(N_spins::Int, boson_level::Int,
                                    direction::Symbol; 
                                    position::Int=Int(ceil(N_spins/2)),
                                    left_state::Int=1, right_state::Int=2)
    spin_pattern = get_label_kink(N_spins, direction, position=position,
                                    left_state=left_state, 
                                    right_state=right_state)
    return vcat(boson_level, spin_pattern)
end

"""
Boson + spin kinks
"""
function get_label_spinboson_domain(N_spins::Int, boson_level::Int,
                                    direction::Symbol; 
                                    start_index::Int=Int(ceil(N_spins/2)),
                                    domain_size::Int=Int(ceil(N_spins/2)),
                                    base_state::Int=1, flip_state::Int=2)
    spin_pattern = get_label_domain(N_spins, direction, 
                                    start_index=start_index,
                                    domain_size=domain_size,
                                    base_state=base_state, 
                                    flip_state=flip_state)
    return vcat(boson_level, spin_pattern)
end

# ============================================================================
# PART 3: Custom State Patterns - User Specifies Every Site
# ============================================================================

"""
Parse custom spin state from config specification.
User manually specifies the state of every site.

Input format: 
  Array of [direction, eigenstate] pairs
  Example: [["Z", 1], ["Z", 2], ["X", 1], ["Y", 2], ...]

Returns pattern ready for product_state(), basically converts the strings into symbols
"""
function parse_spin_custom_pattern(pattern_spec)
    pattern = []
    for site_spec in pattern_spec
        direction = Symbol(site_spec[1])
        eigenstate = site_spec[2]
        push!(pattern, (direction, eigenstate))
    end
    return pattern
end

"""
Parse custom spin-boson state from config specification.
User manually specifies boson level and the state of every spin.

Input format:
{
  "boson_level": 3,
  "spin_pattern": [["Z", 1], ["Z", 2], ["X", 1], ...]
}

Returns pattern ready for product_state()
"""
function parse_spinboson_custom_pattern(boson_level::Int, spin_pattern_spec)
    spin_pattern = parse_spin_custom_pattern(spin_pattern_spec)
    return vcat(boson_level, spin_pattern)
end

# ============================================================================
# PART 4: State Builders - Convert patterns to MPS
# ============================================================================

"""
Build product state from label pattern
Uses existing product_state function
"""
function build_product_from_pattern(sites::Vector{<:AbstractSite}, pattern::Vector)
    return product_state(sites, pattern)
end

"""
Build random MPS with specified bond dimension
Uses existing random_state function
"""
function build_random_mps(sites::Vector{<:AbstractSite}, bond_dim::Int, dtype)
    return random_state(sites, bond_dim, T=dtype)
end

"""
Build random state from config
"""
function build_random_from_config(sites, state_config, system_config)
    params = get(state_config, "params", Dict())
    bond_dim = get(params, "bond_dim", 10)
    dtype = parse_dtype(get(system_config, "dtype", "ComplexF64"))
    
    return build_random_mps(sites, bond_dim, dtype)
end

# ============================================================================
# PART 5: Main Interface - Config → MPS
# ============================================================================

"""
    build_mps_from_config(config)

Main entry point: takes config dict/JSON, returns MPS.

State types:
- "prebuilt": Common patterns (polarized, neel, domain_wall, kink, etc.)
- "custom": User manually specifies every site
- "random": Random MPS with specified bond dimension
"""
function build_mps_from_config(config)
    # Build sites array
    sites = build_sites_from_config(config["system"])
    
    # Get system and state info
    system_type = config["system"]["type"]
    state_config = config["state"]
    state_type = state_config["type"]
    
    # Dispatch based on state type
    if state_type == "random"
        return build_random_from_config(sites, state_config, config["system"])
        
    elseif state_type == "prebuilt"
        if system_type == "spin"
            return build_spin_prebuilt_state(sites, state_config)
        elseif system_type == "spinboson"
            return build_spinboson_prebuilt_state(sites, state_config, config["system"])
        end
        
    elseif state_type == "custom"
        if system_type == "spin"
            return build_spin_custom_state(sites, state_config)
        elseif system_type == "spinboson"
            return build_spinboson_custom_state(sites, state_config, config["system"])
        end
        
    else
        error("Unknown state type: $state_type. Use 'prebuilt', 'custom', or 'random'")
    end
end

# ───────────────────────────────────────────────────────────────────────────
# Spin-Only Prebuilt States
# ───────────────────────────────────────────────────────────────────────────

function build_spin_prebuilt_state(sites, config)
    name = config["name"]
    params = get(config, "params", Dict())
    N = length(sites)
    
    # Default direction to Z (most common)
    spin_direction = Symbol(get(params, "spin_direction", "Z"))
    
    # Generate pattern based on name
    if name == "polarized"
        eigenstate = get(params, "eigenstate", 2)
        pattern = get_label_polarized(N, spin_direction, eigenstate)
        
    elseif name == "neel"
        even_state = get(params, "even_state", 1)
        odd_state = get(params, "odd_state", 2)
        pattern = get_label_neel(N, spin_direction, even_state=even_state, odd_state=odd_state)
        
    elseif name == "kink"
        position = params["position"]
        left_state = get(params, "left_state", 1)
        right_state = get(params, "right_state", 2)
        pattern = get_label_kink(N, spin_direction, position=position,
                                 left_state=left_state, right_state=right_state)
        
    elseif name == "domain"
        start_index = params["start_index"]
        domain_size = params["domain_size"]
        base_state = get(params, "base_state", 1)
        flip_state = get(params, "flip_state", 2)
        pattern = get_label_domain(N, spin_direction, start_index=start_index,
                                   domain_size=domain_size,
                                   base_state=base_state, flip_state=flip_state)
        
    else
        error("Unknown spin prebuilt state: $name\n" *
              "Available: polarized, neel, kink, domain")
    end
    
    return build_product_from_pattern(sites, pattern)
end

# ───────────────────────────────────────────────────────────────────────────
# Spin-Boson Prebuilt States
# ───────────────────────────────────────────────────────────────────────────

function build_spinboson_prebuilt_state(sites, config, system_config)
    name = config["name"]
    params = get(config, "params", Dict())
    N_spins = system_config["N_spins"]
    
    # Default parameters
    boson_level = get(params, "boson_level", 0)
    spin_direction = Symbol(get(params, "spin_direction", "Z"))
    
    # Generate pattern based on name
    if name == "polarized"
        spin_eigenstate = get(params, "spin_eigenstate", 2)
        pattern = get_label_spinboson_polarized(N_spins, boson_level,
                                                spin_direction, spin_eigenstate)
        
    elseif name == "neel"
        even_state = get(params, "even_state", 1)
        odd_state = get(params, "odd_state", 2)
        pattern = get_label_spinboson_neel(N_spins, boson_level, spin_direction,
                                          even_state=even_state, odd_state=odd_state)
        
    elseif name == "kink"
        position = params["position"]
        left_state = get(params, "left_state", 1)
        right_state = get(params, "right_state", 2)
        pattern = get_label_spinboson_kink(N_spins, boson_level, spin_direction,
                                           position=position, left_state=left_state,
                                           right_state=right_state)
        
    elseif name == "domain"
        start_index = params["start_index"]
        domain_size = params["domain_size"]
        base_state = get(params, "base_state", 1)
        flip_state = get(params, "flip_state", 2)
        pattern = get_label_spinboson_domain(N_spins, boson_level, spin_direction,
                                             start_index=start_index, domain_size=domain_size,
                                             base_state=base_state, flip_state=flip_state)
        
    else
        error("Unknown spin-boson prebuilt state: $name\n" *
              "Available: polarized, neel, kink, domain")
    end
    
    return build_product_from_pattern(sites, pattern)
end

# ───────────────────────────────────────────────────────────────────────────
# Custom States (User-Defined)
# ───────────────────────────────────────────────────────────────────────────

"""
Build custom spin state where user specifies every site manually
"""
function build_spin_custom_state(sites, config)
    pattern_spec = config["spin_label"]
    N = length(sites)
    
    # Validate length
    @assert length(pattern_spec) == N "Pattern length $(length(pattern_spec)) doesn't match system size $N"
    
    # Parse pattern
    pattern = parse_spin_custom_pattern(pattern_spec)
    
    return build_product_from_pattern(sites, pattern)
end

"""
Build custom spin-boson state where user specifies boson level and every spin manually
"""
function build_spinboson_custom_state(sites, config, system_config)
    boson_level = config["boson_level"]
    spin_pattern_spec = config["spin_label"]
    N_spins = system_config["N_spins"]
    
    # Validate length
    @assert length(spin_pattern_spec) == N_spins "Spin pattern length $(length(spin_pattern_spec)) doesn't match N_spins=$N_spins"
    
    # Parse pattern
    pattern = parse_spinboson_custom_pattern(boson_level, spin_pattern_spec)
    
    return build_product_from_pattern(sites, pattern)
end


