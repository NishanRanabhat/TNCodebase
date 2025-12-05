# Custom XXZ Model: DMRG Example

## Overview

This example demonstrates building a **custom spin model** using channels:
- ✅ Channel-based model definition (full control)
- ✅ XXZ anisotropy with longitudinal field
- ✅ Config-driven workflow
- ✅ Energy convergence tracking

**Complexity:** Intermediate  
**Prerequisites:** Familiarity with prebuilt templates recommended

---

## What This Example Does

### Physics

Finds the ground state of the **XXZ Model with longitudinal field**:

```
H = Jxy Σᵢ (σˣᵢσˣᵢ₊₁ + σʸᵢσʸᵢ₊₁) + Jz Σᵢ σᶻᵢσᶻᵢ₊₁ + hz Σᵢ σᶻᵢ
  = 1.0 × Σᵢ (σˣᵢσˣᵢ₊₁ + σʸᵢσʸᵢ₊₁) + 2.0 × Σᵢ σᶻᵢσᶻᵢ₊₁ + 0.5 × Σᵢ σᶻᵢ
```

**Physical interpretation:**
- **Jxy = 1.0** (in-plane coupling): XY exchange interaction
- **Jz = 2.0** (Ising anisotropy): Enhanced Z-axis coupling (Δ = Jz/Jxy = 2)
- **hz = 0.5** (longitudinal field): External magnetic field in Z direction

**Phase diagram location:**
- Δ = 2 > 1: Ising-like regime (gapped, Néel order tendency)
- hz = 0.5: Partial magnetization, competes with antiferromagnetic order

### Why Custom Channels?

This example uses `custom_spin` instead of the `heisenberg` prebuilt template to demonstrate:

1. **Explicit channel definition** - See exactly what terms enter the Hamiltonian
2. **Full flexibility** - Easy to add/remove/modify individual terms
3. **Learning tool** - Understand how TNCodebase constructs MPOs

**Equivalent prebuilt config would be:**
```json
"name": "heisenberg",
"params": {"Jx": 1.0, "Jy": 1.0, "Jz": 2.0, "hx": 0.0, "hy": 0.0, "hz": 0.5}
```

---

## Files

```
xxz_custom/
├── dmrg_README.md              # This file
├── dmrg_config.json       # Custom channel configuration
├── dmrg_run.jl            # Main script
```

---

## Usage

### Quick Start

```bash
# Navigate to this directory
cd examples/00_quickstart_dmrg/XXZ_custom

# Run the example
julia dmrg_run.jl
```

### Expected Output

```
MODEL: custom_spin
  Description: XXZ model: H = J_xy*(XX + YY) + J_z*ZZ + h*Z

  CHANNELS:
  [1] FiniteRangeCoupling:
      X ⊗ X, range=1, strength=1.0
      → XX coupling: J_x * sum_i S^x_i S^x_{i+1}
  [2] FiniteRangeCoupling:
      Y ⊗ Y, range=1, strength=1.0
      → YY coupling: J_y * sum_i S^y_i S^y_{i+1}
  [3] FiniteRangeCoupling:
      Z ⊗ Z, range=1, strength=2.0
      → ZZ coupling: J_z * sum_i S^z_i S^z_{i+1}
  [4] Field:
      Z, strength=0.5
      → Longitudinal field: hz * sum_i S^z_i
```

---

## Understanding the Configuration

### Channel Types

The config uses two channel types:

#### FiniteRangeCoupling
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z",
  "op2": "Z",
  "range": 1,
  "strength": 2.0
}
```
- **op1, op2**: Operators on neighboring sites
- **range**: Distance between sites (1 = nearest neighbor)
- **strength**: Coefficient in Hamiltonian

#### Field
```json
{
  "type": "Field",
  "op": "Z",
  "strength": 0.5
}
```
- **op**: Single-site operator
- **strength**: Field strength applied to all sites

### Available Operators

| Symbol | Operator | Notes |
|--------|----------|-------|
| `X` | σˣ (Pauli X) | Real |
| `Y` | σʸ (Pauli Y) | Imaginary → requires ComplexF64 |
| `Z` | σᶻ (Pauli Z) | Real |
| `Sp` | σ⁺ (raising) | Complex |
| `Sm` | σ⁻ (lowering) | Complex |
| `I` | Identity | Real |

### Available Channel Types

| Type | Description | Parameters |
|------|-------------|------------|
| `FiniteRangeCoupling` | Two-site interaction | op1, op2, range, strength |
| `Field` | Single-site term | op, strength |
| `PowerLawCoupling` | Long-range 1/r^α | op1, op2, strength, alpha, n_exp, N |
| `ExpChannelCoupling` | Exponential decay | op1, op2, amplitude, decay |

---

## Modifying the Example

### Try These Variations

**1. Pure XXZ (no field):**
```json
{
  "type": "Field",
  "op": "Z",
  "strength": 0.0
}
```

**2. Isotropic Heisenberg:**
Change ZZ strength to match XX/YY:
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z", "op2": "Z",
  "range": 1,
  "strength": 1.0
}
```

**3. XY model (no Ising term):**
Remove or set ZZ coupling to zero:
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z", "op2": "Z",
  "range": 1,
  "strength": 0.0
}
```

**4. Add transverse field:**
Add a new channel:
```json
{
  "type": "Field",
  "op": "X",
  "strength": 0.3,
  "description": "Transverse field: hx * sum_i S^x_i"
}
```

**5. Next-nearest neighbor coupling:**
```json
{
  "type": "FiniteRangeCoupling",
  "op1": "Z", "op2": "Z",
  "range": 2,
  "strength": 0.5,
  "description": "NNN Ising: J2 * sum_i S^z_i S^z_{i+2}"
}
```
---

## Custom vs Prebuilt: When to Use Which

### Use Prebuilt Templates When:
✅ Standard model (TFIM, Heisenberg, etc.)  
✅ Quick setup needed  
✅ Don't need to see internal structure

### Use Custom Channels When:
✅ Non-standard interactions (DM, ring exchange, etc.)  
✅ Learning how models are built  
✅ Need to add/modify specific terms  
✅ Research on novel Hamiltonians

---

## Physics Notes

### XXZ Phase Diagram

The XXZ model has rich physics depending on anisotropy Δ = Jz/Jxy:

| Δ Range | Phase | Properties |
|---------|-------|------------|
| Δ < -1 | Ferromagnetic | Gapped, all spins aligned |
| -1 < Δ < 1 | XY (Luttinger liquid) | Gapless, power-law correlations |
| Δ = 1 | Heisenberg point | SU(2) symmetric, critical |
| Δ > 1 | Ising (Néel) | Gapped, antiferromagnetic order |

**Our parameters (Δ = 2):** Ising regime with longitudinal field

### Effect of Longitudinal Field

- hz > 0: Favors ↑ spins, induces magnetization
- Competes with antiferromagnetic correlations
- At large hz: Fully polarized state

---

## Troubleshooting

### Issue: "Unknown spin channel type"

**Error:** `Unknown spin channel type: SomeType`

**Solution:** Check channel type spelling. Valid types:
- `FiniteRangeCoupling`
- `Field`
- `PowerLawCoupling`
- `ExpChannelCoupling`

### Issue: Real vs Complex dtype

**Symptom:** Numerical errors or warnings

**Solution:** If using Y, Sp, or Sm operators, must use:
```json
"dtype": "ComplexF64"
```

### Issue: Slow convergence with anisotropy

**Symptom:** Energy still changing after many sweeps

**Solution:** 
- Strong anisotropy (large Δ) may need more sweeps
- Increase chi_max if bond dimension hits limit
- Near phase transitions, convergence is naturally slower

## Summary

This example demonstrates:

✅ **Custom channel definition** - Full control over Hamiltonian  
✅ **XXZ anisotropy** - Jz ≠ Jxy physics  
✅ **Extensibility** - Easy to add new terms  
✅ **Learning tool** - See exactly how models are built

**Custom channels give you complete flexibility for any spin Hamiltonian!**
