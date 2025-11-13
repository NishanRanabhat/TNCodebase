"""
# Entanglement Measures

Functions for computing entanglement properties of MPS represented as vector of tensors.

This module is self-contained and works on Vector{Array} directly, without
requiring MPS wrapper types. Includes internal canonicalization utilities.

## Functions
- `entanglement_spectrum`: Extract Schmidt values at a bond
- `entanglement_entropy`: von Neumann or Renyi entropy
"""

using LinearAlgebra
using TensorOperations

# ============================================================================
# Internal Canonicalization Helpers (for Vector{Array})
# ============================================================================

"""
    _shift_orthogonality_left(A_left, A_right) → (A_left_new, A_right_new)

Internal: Move orthogonality center leftward between two adjacent tensors.
Returns new tensors without modifying inputs.
"""
function _shift_orthogonality_left(A_left::AbstractArray{T,3}, 
                                   A_right::AbstractArray{T,3}) where T
    left_dim, phys_dim, right_dim = size(A_right)
    
    # SVD of right tensor
    F = svd(reshape(A_right, left_dim, phys_dim * right_dim))
    A_right_new = reshape(F.Vt, (:, phys_dim, right_dim))
    US = F.U * Diagonal(F.S)
    
    # Absorb US into left tensor (with normalization)
    @tensoropt A_left_new[-1,-2,-3] := A_left[-1,-2,4] * US[4,-3] / norm(F.S)
    
    return A_left_new, A_right_new
end

"""
    _shift_orthogonality_right(A_left, A_right) → (A_left_new, A_right_new)

Internal: Move orthogonality center rightward between two adjacent tensors.
Returns new tensors without modifying inputs.
"""
function _shift_orthogonality_right(A_left::AbstractArray{T,3}, 
                                    A_right::AbstractArray{T,3}) where T
    left_dim, phys_dim, right_dim = size(A_left)
    
    # SVD of left tensor
    F = svd(reshape(A_left, left_dim * phys_dim, right_dim))
    A_left_new = reshape(F.U, (left_dim, phys_dim, :))
    SV = Diagonal(F.S) * F.Vt
    
    # Absorb SV into right tensor (with normalization)
    @tensoropt A_right_new[-1,-2,-3] := SV[-1,4] * A_right[4,-2,-3] / norm(F.S)
    
    return A_left_new, A_right_new
end

"""
    _canonicalize_at_bond!(psi, bond)

Internal: Put MPS (as vector of tensors) in canonical form at a bond.
Sites 1:bond are left-canonical, sites bond+1:N are right-canonical.
Modifies psi in place.
"""
function _canonicalize_at_bond!(psi::Vector{<:AbstractArray{T,3}}, bond::Int) where T
    N = length(psi)
    @assert 1 ≤ bond < N "Bond must be between 1 and N-1"
    
    # Right-canonicalize from right to bond+1
    @inbounds for site in N-1:-1:bond
        psi[site], psi[site+1] = _shift_orthogonality_left(psi[site], psi[site+1])
    end
    
    # Left-canonicalize from left to bond
    @inbounds for site in 1:bond-1
        psi[site], psi[site+1] = _shift_orthogonality_right(psi[site], psi[site+1])
    end
    
    return nothing
end

# ============================================================================
# Entanglement Spectrum
# ============================================================================

"""
    entanglement_spectrum(bond, psi; n_values=nothing) → Vector{Float64}

Extract Schmidt spectrum at a bond.

Canonicalizes the MPS at the specified bond and extracts the Schmidt values
from the SVD of the bond tensor.

# Arguments
- `bond::Int`: Bond index (between site `bond` and `bond+1`)
- `psi::Vector{<:AbstractArray{T,3}}`: MPS as vector of 3D tensors
- `n_values::Union{Int,Nothing}=nothing`: Number of values to return (all if nothing)

# Returns
- `Vector{Float64}`: Schmidt values lamdaᵢ in descending order

# Example
```julia
# Full spectrum
spectrum = entanglement_spectrum(50, mps)

# Top 20 Schmidt values
spectrum_top = entanglement_spectrum(50, mps, n_values=20)

# Participation ratio
PR = 1 / sum(spectrum.^4)
```
"""
function entanglement_spectrum(bond::Int, psi::Vector{<:AbstractArray{T,3}};
                               n_values::Union{Int,Nothing}=nothing) where T
    N = length(psi)
    @assert 1 ≤ bond < N "Bond must be between 1 and N-1"
    
    # Work on a copy to avoid modifying input
    psi_work = deepcopy(psi)
    
    # Canonicalize at the bond
    _canonicalize_at_bond!(psi_work, bond)
    
    # Extract Schmidt values from canonical bond tensor
    A = psi_work[bond]
    left_dim, phys_dim, right_dim = size(A)
    A_matrix = reshape(A, left_dim * phys_dim, right_dim)
    
    # SVD gives Schmidt decomposition
    F = svd(A_matrix)
    schmidt_values = F.S ./ norm(F.S)
    
    # Remove numerical noise
    schmidt_values = schmidt_values[schmidt_values .> 1e-14]
    
    # Sort in descending order
    sort!(schmidt_values, rev=true)
    
    # Return requested number of values
    if n_values !== nothing
        n_values = min(n_values, length(schmidt_values))
        return schmidt_values[1:n_values]
    else
        return schmidt_values
    end
end

# ============================================================================
# Entanglement Entropy
# ============================================================================

"""
    entanglement_entropy(bond, psi; alpha=1) → Float64

Compute entanglement entropy across a bond.

Uses entanglement_spectrum to get Schmidt values, then computes entropy.
- alpha=1: von Neumann entropy S = -∑ lamdaᵢ² log(lamdaᵢ²)
- alpha≠1: Renyi entropy Sₐ = 1/(1-α) log(∑ lamdaᵢ^(2α))

# Arguments
- `bond::Int`: Bond index (between site `bond` and `bond+1`)
- `psi::Vector{<:AbstractArray{T,3}}`: MPS as vector of 3D tensors
- `alpha::Real=1`: Renyi index (alpha=1 gives von Neumann entropy)

# Returns
- `Float64`: Entanglement entropy

# Example
```julia
# von Neumann entropy
S = entanglement_entropy(50, mps)

# Renyi-2 entropy
S_2 = entanglement_entropy(50, mps, alpha=2)

# Entropy profile
S_profile = [entanglement_entropy(i, mps) for i in 1:N-1]
```
"""
function entanglement_entropy(bond::Int, psi::Vector{<:AbstractArray{T,3}}; 
                              alpha::Real=1) where T
    @assert alpha > 0 "Alpha must be positive"
    
    # Get Schmidt spectrum
    schmidt_values = entanglement_spectrum(bond, psi)
    
    # Compute entropy based on alpha
    if alpha ≈ 1
        # von Neumann entropy: S = -∑ lamdaᵢ² log(lamdaᵢ²)
        eigenvalues = schmidt_values .^ 2
        S = -sum(lamda * log(lamda) for lamda in eigenvalues if lamda > 1e-14)
        return S
    else
        # Renyi entropy: Sₐ = 1/(1-α) log(∑ lamdaᵢ^(2α))
        eigenvalues = schmidt_values .^ 2
        return log(sum(lamda^alpha for lamda in eigenvalues)) / (1 - alpha)
    end
end

# ============================================================================
# Convenience Functions
# ============================================================================

"""
    all_entanglement_entropies(psi; alpha=1) → Vector{Float64}

Compute entanglement entropy at all bonds.

# Example
```julia
S_all = all_entanglement_entropies(mps)
```
"""
function all_entanglement_entropies(psi::Vector{<:AbstractArray{T,3}}; 
                                    alpha::Real=1) where T
    N = length(psi)
    entropies = Vector{Float64}(undef, N-1)
    
    @inbounds for bond in 1:N-1
        entropies[bond] = entanglement_entropy(bond, psi, alpha=alpha)
    end
    
    return entropies
end
