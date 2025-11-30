# Prebuilt Spin-Boson: Vacuum + Neel

## Overview

Example using the `neel` prebuilt template for spin-boson systems. Boson in Fock state + alternating spin pattern.

---

## Configuration

```json
{
  "system": {
    "type": "spinboson",
    "N_spins": 20,
    "nmax": 5,
    "S": 0.5
  },
  "state": {
    "type": "prebuilt",
    "name": "neel",
    "params": {
      "boson_level": 0,
      "spin_direction": "Z",
      "even_state": 1,
      "odd_state": 2
    }
  }
}
```

### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `boson_level` | Int | 0 | Boson Fock state n (0 ≤ n ≤ nmax) |
| `spin_direction` | String | "Z" | Spin eigenbasis ("X", "Y", "Z") |
| `even_state` | Int | 1 | Eigenstate for even spin sites |
| `odd_state` | Int | 2 | Eigenstate for odd spin sites |

---

## What It Creates

**Pattern (N_spins=5, boson_level=0):**
```
Site 1: Boson |0⟩ (vacuum)
Site 2: Spin (Z, 2)  [odd]
Site 3: Spin (Z, 1)  [even]
Site 4: Spin (Z, 2)  [odd]
Site 5: Spin (Z, 1)  [even]
Site 6: Spin (Z, 2)  [odd]
```

**Heterogeneous:** First site is boson, remaining sites are spins with alternating pattern.

---

## Architecture

**MPS Structure:**
```
Site 1: [1 × 6 × 1]  (boson, d=nmax+1=6)
Site 2: [1 × 2 × 1]  (spin)
Site 3: [1 × 2 × 1]  (spin)
...
Site N: [1 × 2 × 1]  (spin)
```

**Heterogeneous product state:**
- Different site dimensions: d_boson = nmax+1, d_spin = 2
- Bond dimension: χ = 1
- No entanglement
- Pattern: |ψ⟩ = |n⟩_boson ⊗ |s₁⟩ ⊗ |s₂⟩ ⊗ ...

**Memory:** Small (~(N_spins × 2 + 1 × (nmax+1)) × 8 bytes)

---

## How It Was Built

### Step 1: System Construction
```json
"system": {
  "type": "spinboson",
  "N_spins": 20,
  "nmax": 5
}
```

Creates: [BosonSite(nmax=5), SpinSite, SpinSite, ...]

### Step 2: Pattern Generation
Template creates heterogeneous label pattern:
```julia
pattern = [
  boson_level,                 # Site 1 (boson)
  (direction, odd_state),      # Site 2 (spin, odd)
  (direction, even_state),     # Site 3 (spin, even)
  (direction, odd_state),      # Site 4 (spin, odd)
  ...
]
```

### Step 3: MPS Construction
Builds product state from pattern:
```julia
mps = product_state(sites, pattern)
```

First site gets boson Fock state tensor, remaining sites get spin eigenstate tensors.

---

## Usage

```bash
cd examples/states/prebuilt/spinboson/vacuum_neel
julia build_state.jl
```

**Output:**
```
Prebuilt Spin-Boson: Vacuum + Neel

System: 1 boson + 20 spins
Boson cutoff: nmax = 5

MPS Structure:
  Site 1 (boson): [1 × 6 × 1]
  Site 2 (spin):  [1 × 2 × 1]
  ...

State Pattern:
  Site 1: Boson in Fock state |0⟩
  Site 2: Spin (Z, 2)  [odd]
  Site 3: Spin (Z, 1)  [even]
  ...
```

---

## Parameter Variations

**Vacuum + standard Neel:**
```json
"boson_level": 0, "even_state": 1, "odd_state": 2
```

**One photon + Neel:**
```json
"boson_level": 1, "even_state": 1, "odd_state": 2
```

**Three photons + inverted Neel:**
```json
"boson_level": 3, "even_state": 2, "odd_state": 1
```

---

## See Also

- **All templates:** `examples/states/prebuilt/README.md`
- **Spin-only neel:** `examples/states/prebuilt/spin/neel/`
- **Documentation:** `docs/state_building.md`
