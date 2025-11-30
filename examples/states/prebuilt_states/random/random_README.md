# Random MPS State

## Overview

Example using random MPS initialization. Non-product state with specified bond dimension.

---

## Configuration

```json
{
  "system": {
    "type": "spin",
    "N": 20,
    "S": 0.5,
    "dtype": "ComplexF64"
  },
  "state": {
    "type": "random",
    "params": {
      "bond_dim": 10
    }
  }
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bond_dim` | Int | 10 | Bond dimension χ for internal bonds |

---

## What It Creates

**Random MPS structure:**
- All tensor entries randomly initialized
- Can represent entangled states
- No specific pattern

**Not a product state:** Cannot be written as |ψ⟩ = |s₁⟩ ⊗ |s₂⟩ ⊗ ...

---

## Architecture

**MPS Structure:**
```
Site 1:   [1  × 2 × χ]  (left edge)
Site 2:   [χ  × 2 × χ]  (bulk)
Site 3:   [χ  × 2 × χ]  (bulk)
...
Site N-1: [χ  × 2 × χ]  (bulk)
Site N:   [χ  × 2 × 1]  (right edge)
```

**Random initialization:**
- Bond dimension: χ = `bond_dim` throughout bulk
- Edge bonds: χ = 1 (required)
- All entries: Random complex numbers
- Entanglement: Can represent entangled states

**Memory:** Larger than product states (~N × χ² × d × 16 bytes for ComplexF64)

---

## How It Was Built

### Step 1: State Type Selection
```json
"type": "random"
```

### Step 2: Bond Dimension Specification
```json
"params": {
  "bond_dim": 10
}
```

### Step 3: Random Tensor Generation
For each site, creates random tensor:
```julia
# Left edge
A[1] = rand(ComplexF64, 1, d, χ)

# Bulk
for i in 2:N-1
    A[i] = rand(ComplexF64, χ, d, χ)
end

# Right edge
A[N] = rand(ComplexF64, χ, d, 1)
```

---

## Usage

```bash
cd examples/states/prebuilt/random
julia build_state.jl
```

**Output:**
```
Random MPS State

System: 20 spins
Bond dimension: 10

MPS Structure:
  Site 1 (left edge):  [1 × 2 × 10]
  Site 2 (bulk):       [10 × 2 × 10]
  ...
  Site 20 (right edge): [10 × 2 × 1]

Bond dimensions:
  Bulk bonds: [10, 10, 10, ...]

Memory: 6.25 KB
```

---

## Parameter Variations

**Small bond dimension (faster, less entanglement):**
```json
"bond_dim": 5
```

**Medium bond dimension (balanced):**
```json
"bond_dim": 20
```

**Large bond dimension (expensive, more entanglement):**
```json
"bond_dim": 50
```

---

## Bond Dimension Selection

**Consider:**
- Expected entanglement in ground state
- Available memory
- DMRG will grow χ anyway during sweeps

**Typical values:**
- χ = 5-10: Light entanglement systems
- χ = 10-30: Moderate entanglement
- χ = 30-100: Heavy entanglement

**Note:** Initial χ doesn't need to match DMRG's final χ_max. DMRG grows bonds automatically.

---

## Works for Spin-Boson Too

**Spin-boson config:**
```json
{
  "system": {
    "type": "spinboson",
    "N_spins": 20,
    "nmax": 5
  },
  "state": {
    "type": "random",
    "params": {
      "bond_dim": 10
    }
  }
}
```

Creates random MPS with heterogeneous site dimensions.

---

## See Also

- **All templates:** `examples/states/prebuilt/README.md`
- **Product states:** `examples/states/prebuilt/spin/polarized/`
- **Documentation:** `docs/state_building.md`
