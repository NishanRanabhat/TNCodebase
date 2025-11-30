# Custom Spin-Boson Patterns

## Overview

Example showing how to build custom spin-boson product states by specifying boson Fock state and each spin individually.

**Full flexibility:** Choose boson level + specify (direction, eigenstate) for every spin.

---

## Configuration

```json
{
  "system": {
    "type": "spinboson",
    "N_spins": 8,
    "nmax": 10,
    "S": 0.5
  },
  "state": {
    "type": "custom",
    "boson_level": 4,
    "spin_label": [
      ["Z", 1],
      ["Z", 2],
      ["Z", 1],
      ["Z", 2],
      ["Z", 1],
      ["Z", 2],
      ["Z", 1],
      ["Z", 2]
    ]
  }
}
```

### Label Format

**Boson:** `"boson_level": n`
- Fock state |n⟩
- Must satisfy: 0 ≤ n ≤ nmax

**Each spin:** `[direction, eigenstate]`
- Direction: `"X"`, `"Y"`, or `"Z"`
- Eigenstate: `1` (lowest) or `2` (highest)

**Must specify:**
- 1 boson level
- N_spins labels (one per spin)

---

## What It Creates

**Pattern (as specified in config):**
```
Site 1: Boson |4⟩
Site 2: Spin (Z, 1)  →  |↓⟩
Site 3: Spin (Z, 2)  →  |↑⟩
Site 4: Spin (Z, 1)  →  |↓⟩
Site 5: Spin (Z, 2)  →  |↑⟩
Site 6: Spin (Z, 1)  →  |↓⟩
Site 7: Spin (Z, 2)  →  |↑⟩
Site 8: Spin (Z, 1)  →  |↓⟩
Site 9: Spin (Z, 2)  →  |↑⟩
```

**Heterogeneous:** First site is boson (custom Fock state), remaining sites are spins (custom pattern).

---

## Architecture

**MPS Structure:**
```
Site 1: [1 × 11 × 1]  (boson, d=nmax+1=11)
Site 2: [1 × 2  × 1]  (spin)
Site 3: [1 × 2  × 1]  (spin)
...
Site N: [1 × 2  × 1]  (spin)
```

**Heterogeneous product state:**
- Different site dimensions
- Bond dimension: χ = 1
- No entanglement
- Custom specification for each site

**Memory:** Small (~(N_spins × 2 + 1 × (nmax+1)) × 8 bytes)

---

## How It Was Built

### Step 1: Specify Boson Level

```json
"boson_level": 4
```

Boson in Fock state |4⟩.

### Step 2: Specify Spin Pattern

Define label for each spin:
```json
"spin_label": [
  ["Z", 1],  // Spin 1
  ["Z", 2],  // Spin 2
  ["Z", 1],  // Spin 3
  ...
]
```

### Step 3: Pattern Parsing

Code combines boson and spin patterns:
```julia
pattern = [
  4,                    # Site 1 (boson)
  (Symbol("Z"), 1),     # Site 2 (spin)
  (Symbol("Z"), 2),     # Site 3 (spin)
  ...
]
```

### Step 4: MPS Construction

Builds heterogeneous product state:
```julia
mps = product_state(sites, pattern)
```

First site gets boson Fock state tensor, remaining sites get spin eigenstate tensors.

---

## Usage

```bash
cd examples/states/custom/spinboson_patterns
julia build_state.jl
```

**Output:**
```
Custom Spin-Boson Patterns

System: 1 boson + 8 spins
Boson cutoff: nmax = 10

MPS Structure:
  Site 1 (boson): [1 × 11 × 1]
  Site 2 (spin):  [1 × 2 × 1]
  ...

Custom Pattern:
  Site 1: Boson in Fock state |4⟩
  Site 2: Spin (Z, 1)
  Site 3: Spin (Z, 2)
  ...
```

---

## Example Patterns

### Coherent State Approximation

Multiple photons:
```json
"boson_level": 5,
"spin_label": [
  ["Z", 2], ["Z", 2], ["Z", 2], ["Z", 2]
]
```

### Vacuum + Domain Wall

```json
"boson_level": 0,
"spin_label": [
  ["Z", 1], ["Z", 1],  // Left (down)
  ["Z", 2], ["Z", 2]   // Right (up)
]
```

### Excited Cavity + Mixed Spins

```json
"boson_level": 3,
"spin_label": [
  ["Z", 2],  // Z basis
  ["X", 1],  // X basis
  ["Y", 2],  // Y basis
  ["Z", 1]   // Z basis
]
```

### Single Excitation

One photon + all spins down:
```json
"boson_level": 1,
"spin_label": [
  ["Z", 1], ["Z", 1], ["Z", 1], ["Z", 1]
]
```

Or vacuum + one spin up:
```json
"boson_level": 0,
"spin_label": [
  ["Z", 1],
  ["Z", 2],  // Single excitation
  ["Z", 1], ["Z", 1]
]
```

---

## Custom vs Prebuilt

**Custom (this example):**
- Specify boson level + every spin manually
- Complete flexibility
- Any pattern you want

**Prebuilt:**
- Use templates (polarized, neel, etc.)
- Simpler config
- Standard patterns

**Use custom when:**
- Need specific boson Fock state
- Non-standard spin patterns
- Initial conditions for quench dynamics
- Studying excitation transport

---

## See Also

- **Prebuilt templates:** `examples/states/prebuilt/README.md`
- **Spin-only custom:** `examples/states/custom/spin_patterns/`
- **Prebuilt spin-boson:** `examples/states/prebuilt/spinboson/vacuum_neel/`
- **Documentation:** `docs/state_building.md`
