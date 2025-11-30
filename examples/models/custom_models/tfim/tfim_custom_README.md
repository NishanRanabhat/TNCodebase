# Custom TFIM

## Overview

Simple example showing how to build the Transverse Field Ising Model using custom channels instead of the prebuilt template.

**Model:** TFIM  
**Complexity:** Beginner  

---

## The Model

### Hamiltonian

```
H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ
```

**Parameters in this example:**
- J = -1.0 (ferromagnetic coupling)
- h = 0.5 (transverse field)

**Physical meaning:**
- ZZ term: Spins want to align in Z direction
- X field: Quantum fluctuations flip spins

---

## Building from Channels

### The 2 Channels

**1. ZZ Coupling**
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z",
  "op2": "Z",
  "range": 1,
  "strength": -1.0
}
```
Creates: J Σᵢ σᶻᵢσᶻᵢ₊₁

**2. Transverse Field**
```json
{
  "type": "Field",
  "op": "X",
  "strength": 0.5
}
```
Creates: h Σᵢ σˣᵢ

---

## Usage

### Run the Example

```bash
cd examples/models/custom/tfim
julia build_model.jl
```

### Expected Output

```
Custom TFIM - Channel Construction

Channels defined:
  1. FiniteRangeCoupling → ZZ coupling
  2. Field → Transverse field

MPO Structure:
  Maximum bond dimension: χ = 5

Compare to Prebuilt:
  Custom and prebuilt produce identical MPO!
```

---

## Custom vs Prebuilt

### This Example (Custom)

**Config:**
```json
{
  "model": {
    "name": "custom_spin",
    "params": {
      "channels": [
        {"type": "FiniteRangeCoupling", "op1": "Z", "op2": "Z", ...},
        {"type": "Field", "op": "X", ...}
      ]
    }
  }
}
```

**Advantages:**
- See exactly how model is built
- Can modify any aspect
- Educational

### Prebuilt Template

**Config:**
```json
{
  "model": {
    "name": "transverse_field_ising",
    "params": {
      "J": -1.0,
      "h": 0.5,
      ...
    }
  }
}
```

**Advantages:**
- Simpler config
- Less verbose
- Faster to write

**See:** `examples/models/prebuilt/tfim/`

### When to Use Which

**Use prebuilt when:**
- You want standard TFIM
- Quick exploration
- Standard parameters

**Use custom when:**
- Learning how models are built
- Need non-standard variations
- Want full control

**Both produce identical MPO!**

---

## Configuration

### Complete Config

**Channels:**
```json
"channels": [
  {"type": "FiniteRangeCoupling", "op1": "Z", "op2": "Z", "range": 1, "strength": -1.0},
  {"type": "Field", "op": "X", "strength": 0.5}
]
```

---

## MPO Structure

### Bond Dimension

**For this model:**
- 2 channels → χ = 5
- Minimal structure for TFIM

**General:**
- Each channel adds to bond dimension
- TFIM has smallest χ for non-trivial model
