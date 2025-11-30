# Custom Spin Patterns

## Overview

Example showing how to build custom product states by specifying each site individually.

**Full flexibility:** Specify (direction, eigenstate) for every site.

---

## Configuration

```json
{
  "system": {
    "type": "spin",
    "N": 8,
    "S": 0.5
  },
  "state": {
    "type": "custom",
    "spin_label": [
      ["Z", 1],
      ["Z", 2],
      ["X", 1],
      ["X", 2],
      ["Y", 1],
      ["Y", 2],
      ["Z", 1],
      ["Z", 2]
    ]
  }
}
```

### Label Format

**Each site:** `[direction, eigenstate]`

**Direction:** `"X"`, `"Y"`, or `"Z"`
- Which operator's eigenbasis

**Eigenstate:** `1` or `2`
- `1` = Lowest eigenvalue eigenvector
- `2` = Highest eigenvalue eigenvector

**For spin-1/2:**
- Z: 1 = |↓⟩, 2 = |↑⟩
- X: 1 = |→⟩, 2 = |←⟩
- Y: 1 = |⊙⟩, 2 = |⊗⟩

**Must specify N labels** (one per site).

---

## What It Creates

**Pattern (as specified in config):**
```
Site 1: (Z, 1)  →  |↓⟩_Z
Site 2: (Z, 2)  →  |↑⟩_Z
Site 3: (X, 1)  →  |→⟩_X
Site 4: (X, 2)  →  |←⟩_X
Site 5: (Y, 1)  →  |⊙⟩_Y
Site 6: (Y, 2)  →  |⊗⟩_Y
Site 7: (Z, 1)  →  |↓⟩_Z
Site 8: (Z, 2)  →  |↑⟩_Z
```

**Completely custom:** Each site can be in different basis and eigenstate.

---

## Architecture

**MPS Structure:**
```
Site 1: [1 × 2 × 1]
Site 2: [1 × 2 × 1]
...
Site N: [1 × 2 × 1]
```

**Product state:**
- Bond dimension: χ = 1
- No entanglement between sites
- Custom pattern specified site-by-site

**Memory:** Very small (~N × 2 × 8 bytes)

---

## How It Was Built

### Step 1: Specify Custom Pattern

Define label for each site:
```json
"spin_label": [
  ["Z", 1],  // Site 1
  ["Z", 2],  // Site 2
  ["X", 1],  // Site 3
  ...
]
```

### Step 2: Pattern Parsing

Code converts JSON to internal format:
```julia
pattern = [
  (Symbol("Z"), 1),
  (Symbol("Z"), 2),
  (Symbol("X"), 1),
  ...
]
```

### Step 3: MPS Construction

Builds product state:
```julia
mps = product_state(sites, pattern)
```

Each site gets tensor for its specified eigenstate.

---

## Usage

```bash
cd examples/states/custom/spin_patterns
julia build_state.jl
```

**Output:**
```
Custom Spin Patterns

System: 8 spins
State type: custom

MPS Structure:
  Bond dimensions: [1, 1, 1, ...]
  Memory: 0.12 KB

Custom Pattern:
  Site 1: (Z, 1)
  Site 2: (Z, 2)
  Site 3: (X, 1)
  ...
```

---

## Example Patterns

### Domain Wall

```json
"spin_label": [
  ["Z", 1], ["Z", 1], ["Z", 1],  // Left region (down)
  ["Z", 2], ["Z", 2], ["Z", 2]   // Right region (up)
]
```

### Single Spin Flip

```json
"spin_label": [
  ["Z", 2], ["Z", 2],
  ["Z", 1],  // Flipped spin
  ["Z", 2], ["Z", 2]
]
```

### Mixed Basis

```json
"spin_label": [
  ["Z", 2],  // Z basis
  ["X", 1],  // X basis
  ["Y", 2],  // Y basis
  ["Z", 1]   // Z basis
]
```

### W-State Component

First step toward W-state (single excitation):
```json
"spin_label": [
  ["Z", 1], ["Z", 1],
  ["Z", 2],  // Single up spin
  ["Z", 1], ["Z", 1]
]
```

---

## Custom vs Prebuilt

**Custom (this example):**
- Specify every site manually
- Complete flexibility
- Any pattern you want

**Prebuilt:**
- Use templates (polarized, neel, etc.)
- Simpler config
- Standard patterns

**Use custom when:**
- Need non-standard pattern
- Domain walls at specific positions
- Mixed basis states
- Specific initial conditions for dynamics

---

## See Also

- **Prebuilt templates:** `examples/states/prebuilt/README.md`
- **Spin-boson custom:** `examples/states/custom/spinboson_patterns/`
- **Documentation:** `docs/state_building.md`
