"""
# Contraction Routines

Fundamental tensor network contraction operations for MPS calculations.

## Design Philosophy
- **Single function names** (`contract_right`, `contract_left`) with multiple dispatch
- **Type-based dispatch**: Operator dimensionality determines which method is called
  - 4D array (MPO) → full Hamiltonian contraction  
  - 2D array (Matrix) → local operator contraction
  - No operator → identity contraction (inner product)
- **Dimension-based dispatch**: Environment tensor R's dimensionality indicates contraction type
  - R is 3D → MPO contraction (3-leg environment)
  - R is 2D → Local operator or identity (2-leg environment)

## Tensor Conventions
- MPS tensors: `[left_bond, physical, right_bond]` (3D)
- MPO tensors: `[mpo_left, mpo_right, phys_out, phys_in]` (4D)
- Environment L/R with MPO: `[bond, mpo_bond, bond]` (3D)
- Environment L/R without MPO: `[bond, bond]` (2D)
"""

using LinearAlgebra
using TensorOperations

# ============================================================================
# Right Contractions (sweep left to right)
# ============================================================================

"""
    contract_right(B, R, W) → Environment tensor

Contract MPS tensor B from the right with MPO W and environment R.

# Arguments
- `B::AbstractArray{T1,3}`: MPS tensor [left_bond, physical, right_bond]
- `R::AbstractArray{T2,3}`: Right environment [right_bond, mpo_bond, right_bond]
- `W::AbstractArray{T3,4}`: MPO tensor [mpo_left, mpo_right, phys_out, phys_in]

# Returns
- `AbstractArray{,3}`: Updated environment [left_bond, mpo_bond, left_bond]
"""

function contract_right(B::AbstractArray{T1,3}, R::AbstractArray{T2,3}, W::AbstractArray{T3,4}) where {T1<:Number, T2<:Number, T3<:Number}
    @tensoropt fin[-1,-2,-3] := conj(B)[-1,4,5]*R[5,6,7]*W[-2,6,4,8]*B[-3,8,7]
    return fin
end


"""
    contract_right(B, R, O) → Environment tensor

Contract MPS tensor B from the right with local operator O.

# Arguments
- `B::AbstractArray{T1,3}`: MPS tensor
- `R::AbstractArray{T2,2}`: Right environment [right_bond, right_bond]
- `O::AbstractArray{T3,2}`: Local operator [phys_out, phys_in]

# Returns
- `AbstractArray{,2}`: Updated environment [left_bond, left_bond]
"""

function contract_right(B::AbstractArray{T1,3}, R::AbstractArray{T2,2}, O::AbstractArray{T3,2}) where {T1<:Number, T2<:Number, T3<:Number}
    @tensoropt fin[-1,-2] := conj(B)[-1,3,4]*R[4,5]*O[3,6]*B[-2,6,5]
    return fin
end

"""
    contract_right(B, R) → Environment tensor

Contract MPS tensor B from the right (identity operator / inner product).

# Arguments
- `B::AbstractArray{T1,3}`: MPS tensor
- `R::AbstractArray{T2,2}`: Right environment

# Returns
- `AbstractArray{,2}`: Updated environment [left_bond, left_bond]
"""

function contract_right(B::AbstractArray{T1,3}, R::AbstractArray{T2,2}) where {T1<:Number, T2<:Number}
    @tensoropt fin[-1,-2] := conj(B)[-1,3,4]*R[4,5]*B[-2,3,5]
    return fin
end

# ============================================================================
# Left Contractions (sweep right to left)
# ============================================================================

"""
    contract_left(A, L, W) → Environment tensor

Contract MPS tensor A from the left with MPO W and environment L.

# Arguments
- `A::AbstractArray{T1,3}`: MPS tensor [left_bond, physical, right_bond]
- `L::AbstractArray{T2,3}`: Left environment [left_bond, mpo_bond, left_bond]
- `W::AbstractArray{T3,4}`: MPO tensor [mpo_left, mpo_right, phys_out, phys_in]

# Returns
- `AbstractArray{,3}`: Updated environment [right_bond, mpo_bond, right_bond]
"""

function contract_left(A::AbstractArray{T1,3},L::AbstractArray{T2,3},W::AbstractArray{T3,4}) where {T1<:Number, T2<:Number, T3<:Number}
    @tensoropt fin[-1,-2,-3] := conj(A)[5,4,-1]*L[5,6,7]*W[6,-2,4,8]*A[7,8,-3]
    return fin
end

"""
    contract_left(A, L, O) → Environment tensor

Contract MPS tensor A from the left with local operator O.

# Arguments
- `A::AbstractArray{T1,3}`: MPS tensor
- `L::AbstractArray{T2,2}`: Left environment [left_bond, left_bond]
- `O::AbstractArray{T3,2}`: Local operator [phys_out, phys_in]

# Returns
- `AbstractArray{,2}`: Updated environment [right_bond, right_bond]
"""

function contract_left(A::AbstractArray{T1,3},L::AbstractArray{T2,2},O::AbstractArray{T3,2}) where {T1<:Number, T2<:Number, T3<:Number}
    @tensoropt fin[-1,-2] := conj(A)[4,3,-1]*L[4,5]*O[3,6]*A[5,6,-2]
    return fin
end

"""
    contract_left(A, L) → Environment tensor

Contract MPS tensor A from the left (identity operator / inner product).

# Arguments
- `A::AbstractArray{T1,3}`: MPS tensor
- `L::AbstractArray{T2,2}`: Left environment

# Returns
- `AbstractArray{,2}`: Updated environment [right_bond, right_bond]
"""

function contract_left(A::AbstractArray{T1,3},L::AbstractArray{T2,2}) where {T1<:Number, T2<:Number}
    @tensoropt fin[-1,-2] :=  conj(A)[4,3,-1]*L[4,5]*A[5,3,-2]
    return fin
end






