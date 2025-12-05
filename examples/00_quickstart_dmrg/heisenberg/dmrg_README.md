# Heisenberg Model: Complete DMRG Example

## Overview

This example demonstrates a complete DMRG ground state search for the **Heisenberg model**:
- ✅ Config-driven workflow (all parameters in JSON)
- ✅ Automatic model building (Heisenberg Model)
- ✅ Random initial state (standard for DMRG)
- ✅ Energy convergence tracking
- ✅ Automatic data saving with reproducible indexing

**Complexity:** Beginner-friendly  
**Prerequisites:** Package installed and activated

---

## What This Example Does

### Physics

Finds the ground state of the **Heisenberg Model**:

```
H = Jx Σᵢ σˣᵢσˣᵢ₊₁ + Jy Σᵢ σʸᵢσʸᵢ₊₁ + Jz Σᵢ σᶻᵢσᶻᵢ₊₁ + hx Σᵢ σˣᵢ + hy Σᵢ σʸᵢ + hz Σᵢ σᶻᵢ
  = 1.0 × Σᵢ σˣᵢσˣᵢ₊₁ + 1.0 × Σᵢ σʸᵢσʸᵢ₊₁ + 1.0 × Σᵢ σᶻᵢσᶻᵢ₊₁
```

**Physical interpretation:**
- **Jx = Jy = Jz = 1.0** (isotropic antiferromagnetic): Full SU(2) symmetry
- **hx = hy = hz = 0.0** (no external field): Pure exchange interaction
- **Ground state:** Antiferromagnetically correlated singlet state

**Our parameters:**
- Isotropic Heisenberg (XXX model)
- Ground state has power-law spin correlations
- Requires complex dtype due to Y operators

### Algorithm

Uses **Density Matrix Renormalization Group (DMRG)**:

1. Start with random MPS (bond dimension χ=5)
2. Sweep left-right across chain
3. At each site, minimize local energy via Lanczos
4. Grow bond dimension as needed (up to χ_max=100)
5. Repeat until energy converges (50 sweeps)

**Convergence:**
- Energy should stabilize after 20-30 sweeps
- Bond dimension grows to capture entanglement
- Final energy change ΔE < 10⁻⁸

---

## Files

```
heisenberg/
├── dmrg_README.md              # This file
├── dmrg_config.json       # All simulation parameters
├── dmrg_run.jl            # Main script
```

---

## Usage

### Quick Start

```bash
# Navigate to this directory
cd examples/00_quickstart/heisenberg

# Run the example
julia dmrg_run.jl
```

That's it! The script will:
1. Load configuration from `dmrg_config.json`
2. Build the Heisenberg Hamiltonian (automatic)
3. Create random initial state (automatic)
4. Run DMRG for 50 sweeps
5. Save data to `TNCodebase/data/` (automatic)

### Expected Output

You should see:
- Configuration summary
- Progress through sweeps
- Convergence confirmation
- Location of saved data

---

## Understanding the Configuration

The `dmrg_config.json` file has four main sections:

### 1. System
```json
"system": {
  "type": "spin",
  "N": 20
}
```
- Defines 20 spin-1/2 sites
- Each site has dimension d=2 (up/down states)

### 2. Model
```json
"model": {
  "name": "heisenberg",
  "params": {
    "N": 20,
    "Jx": 1.0,
    "Jy": 1.0,
    "Jz": 1.0,
    "hx": 0.0,
    "hy": 0.0,
    "hz": 0.0,
    "dtype": "ComplexF64"
  }
}
```
- Uses prebuilt Heisenberg template
- Jx = Jy = Jz → isotropic (XXX) model
- All fields zero → pure exchange
- ComplexF64 required for Y operators

### 3. State
```json
"state": {
  "type": "random",
  "params": {"bond_dim": 5}
}
```
- Random MPS with bond dimension 5
- Standard starting point for DMRG
- DMRG will optimize this state

### 4. Algorithm
```json
"algorithm": {
  "type": "dmrg",
  "options": {
    "chi_max": 100,
    "n_sweeps": 50,
    ...
  }
}
```
- DMRG with max bond dimension 100
- 50 left-right sweeps
- Lanczos eigensolver

---

## Modifying the Example

### Try These Variations

**1. XXZ model (anisotropic):**
```json
"Jx": 1.0, "Jy": 1.0, "Jz": 2.0
```
Expected: Z-axis Néel order enhanced

**2. XY model:**
```json
"Jx": 1.0, "Jy": 1.0, "Jz": 0.0
```
Expected: In-plane correlations only

**3. Add longitudinal field:**
```json
"hz": 0.5
```
Expected: Breaks SU(2) symmetry, induces magnetization

**4. Increase system size:**
```json
"N": 40
```
Expected: Slower convergence, more entanglement

**5. Ferromagnetic Heisenberg:**
```json
"Jx": -1.0, "Jy": -1.0, "Jz": -1.0
```
Expected: Ferromagnetically ordered ground state

---

## Understanding the Output

### During Simulation

You'll see messages showing sweep-by-sweep progress.

### After Completion

**Key results:**
```
Sweep 50 (final):
  Energy:     -8.68...
  Bond dim:   ~30-50
```

**Interpretation:**
- Energy: Ground state energy of Heisenberg chain
- Bond dim: Reflects entanglement (higher than TFIM due to SU(2) symmetry)

**Convergence check:**
```
Energy change (last sweep): 3.14e-09
✓ Converged! (ΔE < 10⁻⁶)
```

### Saved Data

Data is automatically saved to:
```
Package_Dev/data/dmrg/[run_id]/
├── metadata.json           # Convergence info, parameters
├── sweep_001.jld2         # MPS after sweep 1
├── sweep_002.jld2         # MPS after sweep 2
...
└── sweep_050.jld2         # Final MPS (ground state)
```

---

## Physics Notes

### Heisenberg vs TFIM

| Property | Heisenberg (this) | TFIM |
|----------|-------------------|------|
| Symmetry | SU(2) continuous | Z₂ discrete |
| Ground state | Critical, power-law | Ordered or disordered |
| Entanglement | Higher (log scaling) | Lower (area law) |
| Bond dimension | ~30-50 | ~15-30 |
| dtype | ComplexF64 | Float64 |

### Why ComplexF64?

The σʸ operator is imaginary:
```
σʸ = [0  -i]
     [i   0]
```

This requires complex arithmetic throughout the calculation.

### Exact Ground State Energy

For the infinite isotropic Heisenberg chain:
```
E₀/N = 1/4 - ln(2) ≈ -0.4431...
```

For finite chains with open boundaries, expect slight deviations.

---

## Troubleshooting

### Issue: Package not activated

**Error:** `ArgumentError: Package TNCodebase not found`

**Solution:**
```bash
cd /path/to/Package_Dev
julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Issue: Slow convergence

**Symptom:** Energy still changing after 50 sweeps

**Solutions:**
1. Increase `n_sweeps` to 70 or 100
2. Increase `chi_max` to 150 or 200
3. Heisenberg naturally needs more sweeps than TFIM

### Issue: High bond dimension

**Symptom:** Bond dimension hits chi_max

**Solution:** Increase chi_max - Heisenberg ground states have more entanglement than TFIM

---

## See Also

**Related Examples:**
- `examples/models/prebuilt/tfim/` - TFIM model (simpler)
- `examples/models/prebuilt/long_range_ising/` - Long-range interactions

**Documentation:**
- `docs/model_building.md` - How models are built
- `docs/prebuilt_templates.md` - All prebuilt templates

---

## Summary

This example demonstrates:

✅ **Heisenberg model** - Full SU(2) symmetric spin chain  
✅ **Automatic construction** - No manual tensor manipulation  
✅ **Complex arithmetic** - Handled automatically  
✅ **Professional output** - Organized data, metadata tracking

**You've successfully run Heisenberg DMRG with TNCodebase!**
