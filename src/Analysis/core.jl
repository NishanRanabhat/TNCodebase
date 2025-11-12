using LinearAlgebra

"""
    inner_product(psi, N) → scalar

Calculate the inner product ⟨ψ|ψ⟩ of an MPS/MPDO.

Uses identity contractions (no operator) by sweeping from right to left.
For a normalized state, this should return 1.0.

# Arguments
- `psi::Vector{<:AbstractArray{T,3}}`: MPS as array of 3D tensors (for MPS)
- `psi::Vector{<:AbstractArray{T,4}}`: Or array of 4D tensors (for MPDO)
- `N::Int`: Number of sites

# Returns
- Scalar value of ⟨ψ|ψ⟩

# Example
```julia
mps = # ... Vector of 3D tensors
norm = inner_product(mps, 20)
println("Norm: ", norm)  # Should be ≈ 1.0 if normalized
```
"""

function inner_product(psi::Vector{<:AbstractArray{T,3}}) where T
    R = ones(1, 1)
    @inbounds for i in reverse(1:length(psi))
        R = contract_right(psi[i], R)  # Identity contraction
    end
    return R[1]
end

"""
    single_site_expectation(site, operator, psi) → scalar

Calculate single-site expectation value ⟨ψ|O_i|ψ⟩.

# Algorithm
1. Contract from right (sites > i) with identity
2. Apply operator at site i
3. Contract from left (sites < i) with identity

# Arguments
- `site::Int`: Site index where operator is applied
- `operator::AbstractArray{T1,2}`: Local operator (physical_dim × physical_dim)
- `psi::Vector{<:AbstractArray{T2,3}}`: MPS state

# Returns
- Scalar expectation value ⟨O_i⟩

# Example
```julia
N = 20
mps = # ... some MPS state
Sz = [0.5 0; 0 -0.5]  # Spin-1/2 Sz operator
magnetization = single_site_expectation(10, Sz, mps)
```
"""

function single_site_expectation(site::Int, operator::AbstractArray{T1,2}, psi::Vector{<:AbstractArray{T2,3}}) where {T1, T2}
    R = ones(1, 1)
    
    # Contract from right with identity (sites after operator)
    @inbounds for i in reverse(site+1:length(psi))
        R = contract_right(psi[i], R)  # Identity contraction
    end
    
    # Apply operator at site
    R = contract_right(psi[site], R, operator)  # Operator contraction
    
    # Contract from left with identity (sites before operator)
    @inbounds for i in reverse(1:site-1)
        R = contract_right(psi[i], R)  # Identity contraction
    end
    
    return R[1]
end

"""
    subsystem_expectation_sum(operator, psi, l, m) → scalar

Compute the sum of expectation values ⟨∑ᵢ Oᵢ⟩ for sites i ∈ [l, m].

Generic implementation without assuming canonical form. Efficiently computes
total expectation value over a subsystem by building environments once.

# Arguments
- `operator::AbstractArray{T1,2}`: Local operator to measure
- `psi::Vector{<:AbstractArray{T2,3}}`: MPS state
- `l::Int`: Starting site of subsystem (1 ≤ l ≤ N)
- `m::Int`: Ending site of subsystem (l ≤ m ≤ N)

# Returns
- Scalar: ⟨O_l⟩ + ⟨O_{l+1}⟩ + ... + ⟨O_m⟩

# Examples
```julia
Sz = [0.5 0; 0 -0.5]

# Total magnetization in full system
total_mag = subsystem_expectation_sum(Sz, mps, 1, N)

# Magnetization in central region  
center_mag = subsystem_expectation_sum(Sz, mps, 40, 60)

# Single site expectation
site_mag = subsystem_expectation_sum(Sz, mps, 10, 10)
```
"""

function subsystem_expectation_sum(operator::AbstractArray{T1,2}, 
                                   psi::Vector{<:AbstractArray{T2,3}},
                                   l::Int, m::Int) where {T1, T2}
    N = length(psi)
    @assert 1 ≤ l ≤ m ≤ N "Invalid subsystem range: must have 1 ≤ l ≤ m ≤ N"
    
    # Build right environments from [l+1, N] (we only need R[l+1] onwards)
    R_envs = Dict{Int, Any}()
    R_envs[N+1] = ones(1, 1)
    
    @inbounds for i in reverse(l+1:N)  # Start from l+1, not l!
        R_envs[i] = contract_right(psi[i], R_envs[i+1])
    end
    
    # Build left environment from [1, l-1]
    L = ones(1, 1)
    if l > 1
        @inbounds for i in 1:l-1
            L = contract_left(psi[i], L)
        end
    end
    
    # Compute sum (uses R_envs[i+1] for i in [l, m])
    expectation_sum = 0.0
    
    @inbounds for i in l:m
        temp = contract_left(psi[i], L, operator)
        @tensoropt expectation_sum += temp[1,2] * R_envs[i+1][1,2]  # Needs R[l+1], R[l+2], ..., R[m+1]
        
        if i < m
            L = contract_left(psi[i], L)
        end
    end
    
    return expectation_sum
end