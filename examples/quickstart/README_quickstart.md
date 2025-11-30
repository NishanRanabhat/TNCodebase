# Quickstart: Complete DMRG Example

## Overview

**Start here if you're new to TNCodebase!**

This example demonstrates a complete DMRG ground state search from start to finish:
- ✅ Config-driven workflow (all parameters in JSON)
- ✅ Automatic model building (Transverse Field Ising Model)
- ✅ Random initial state (standard for DMRG)
- ✅ Energy convergence tracking
- ✅ Automatic data saving with reproducible indexing

**Complexity:** Beginner-friendly  
**Prerequisites:** Package installed and activated

---

## What This Example Does

### Physics

Finds the ground state of the **Transverse Field Ising Model (TFIM)**:

```
H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ
  = -1.0 × Σᵢ σᶻᵢσᶻᵢ₊₁ + 0.5 × Σᵢ σˣᵢ
```

**Physical interpretation:**
- **J = -1.0** (ferromagnetic): Neighboring spins want to align in Z direction
- **h = 0.5** (transverse field): Quantum fluctuations try to flip spins to X direction
- **Competition:** J vs h determines the ground state

**Our parameters (h=0.5):**
- Well below critical point
- Ground state is magnetically ordered

### Algorithm

Uses **Density Matrix Renormalization Group (DMRG)**:

1. Start with random MPS (bond dimension χ=5)
2. Sweep left-right across chain
3. At each site, minimize local energy via Lanczos
4. Grow bond dimension as needed (up to χ_max=100)
5. Repeat until energy converges (50 sweeps)

**Convergence:**
- Energy should stabilize after 20-30 sweeps
- Bond dimension grows to ~15-30 (true entanglement of ground state)
- Final energy change ΔE < 10⁻⁸

---

## Files

```
00_quickstart/
├── README.md              # This file
├── config.json            # All simulation parameters
├── run_dmrg.jl            # Main script
└── expected_output.txt    # What you should see
```

---

## Usage

### Quick Start

```bash
# Navigate to this directory
cd examples/00_quickstart

# Run the example
julia run_dmrg.jl
```

That's it! The script will:
1. Load configuration from `config.json`
2. Build the TFIM Hamiltonian (automatic)
3. Create random initial state (automatic)
4. Run DMRG for 20 sweeps
5. Save data to `Package_Dev/data/`
6. Display results

### Expected Output

You should see:
- Configuration summary
- Progress through sweeps
- Final energy: E₀ ≈ -18.95 to -19.0
- Convergence confirmation
- Location of saved data

See `expected_output.txt` for the complete output.

---

## Understanding the Configuration

The `config.json` file has four main sections:

### 1. System
```json
"system": {
  "type": "spin",
  "N": 20,
  "S": 0.5
}
```
- Defines 20 spin-1/2 sites
- Each site has dimension d=2 (up/down states)

### 2. Model
```json
"model": {
  "name": "transverse_field_ising",
  "params": {
    "J": -1.0,
    "h": 0.5,
    ...
  }
}
```
- Uses prebuilt TFIM template
- J < 0 → ferromagnetic coupling
- h = 0.5 → transverse field strength

**See `examples/models/prebuilt/tfim/` for model details**

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

**See `examples/states/` for other initial states**

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

**1. Change to disordered phase:**
```json
"h": 1.5  // Change from 0.5 to 1.5 (above critical point)
```
**2. Increase system size:**
```json
"N": 40  // Change from 20 to 40
```
**3. Reduce bond dimension:**
```json
"chi_max": 30  // Change from 100 to 30
```
Expected: Faster runtime, slightly higher energy (truncation error)

**4. Add more sweeps:**
```json
"n_sweeps": 80  // Change from 50 to 80
```
Expected: Better convergence confirmation

---

## Understanding the Output

### During Simulation

You'll see messages like:
```
Starting DMRG simulation...
```

Your actual implementation may print sweep-by-sweep progress. That's normal!

### After Completion

**Key results:**
```
Sweep 50 (final):
  Bond dim:   18
```

**Interpretation:**
- Energy: Close to exact ground state
- Bond dim < chi_max: Converged (no truncation needed)

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
└── sweep_020.jld2         # Final MPS (ground state)
```

**Run ID format:** `YYYYMMDD_HHMMSS_[hash]`
- Timestamp: When simulation started
- Hash: First 8 chars of config hash (reproducibility)

---

## What Makes This Work

### TNCodebase Features Demonstrated

**1. Config-driven workflow:**
- Everything specified in JSON
- No hardcoding in scripts
- Easy to modify and track

**2. Automatic builders:**
- `build_mpo_from_config()` → Creates Hamiltonian
- `build_mps_from_config()` → Creates initial state
- `run_simulation_from_config()` → Runs algorithm

**3. Hash-based indexing:**
- Same config → same hash → same directory
- Different config → different hash → different directory
- Automatic deduplication and reproducibility

**4. Metadata tracking:**
- All parameters saved automatically
- Convergence data preserved
- Easy to analyze later

---

## Next Steps

### Learn the Builders

**Model building:**
- See `examples/models/` for how to construct Hamiltonians
- Read `docs/model_building.md` for comprehensive guide

**State building:**
- See `examples/states/` for initial state preparation
- Read `docs/state_building.md` for detailed documentation

### Try Other Algorithms

**Time evolution:**
- `examples/tdvp/` - Quantum quench dynamics
- Uses TDVP instead of DMRG

### Explore Advanced Features

**Custom models:**
- `examples/models/custom/` - Build from channels
- `examples/models/custom/advanced_fsm/` - Power-law interactions

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

Then run the example again.

### Issue: Slow convergence

**Symptom:** Energy still changing after 50 sweeps

**Solutions:**
1. Increase `n_sweeps` to 70 or 100
2. Increase `chi_max` to 150 or 200
3. Check if you're at critical point (h ≈ 1.0)

### Issue: Unexpected energy

**Expected:** E₀ ≈ -18.95 to -19.0 for h=0.5, N=20

**If very different:**
1. Check J and h in config
2. Verify N matches between system and model
3. Look for convergence warnings

---

## Technical Details

### Why These Parameters?

**N = 20:**
- Medium size - shows non-trivial physics
- Fast enough for quick testing (~5-10 seconds)
- Good balance for demonstrations

**chi_max = 100:**
- True ground state needs χ ≈ 15-20
- chi_max=100 ensures no truncation
- Allows exact result with plenty of margin

**Random initial state with bond_dim=5:**
- Prevents symmetry sectors from being missed
- Small enough to start quickly
- DMRG grows it as needed (to ~15-20)

**50 sweeps:**
- Typical convergence: 20-30 sweeps
- Extra sweeps confirm convergence
- Each sweep is very fast (~0.1-0.2 sec)

### Computational Cost

**Time complexity per sweep:** O(N × χ³ × d³)
- N = 20 (system size)
- χ ≈ 18 (average bond dimension)
- d = 2 (local dimension)

**Memory:** ~0.5-1 MB for MPS, environments, and MPO

**Total runtime:** 5-10 seconds on modern laptop

---

## See Also

**Documentation:**
- `docs/model_building.md` - How models are built
- `docs/state_building.md` - How states are prepared

**Related Examples:**
- `examples/models/prebuilt/tfim/` - TFIM model details
- `examples/dmrg/` - More DMRG examples
- `examples/tdvp/` - Time evolution

**Advanced Topics:**
- `examples/models/custom/advanced_fsm/` - Power-law interactions
- Observable calculations (coming soon)

---

## Summary

This quickstart example demonstrates:

✅ **Complete workflow** - Config → Build → Run → Save  
✅ **Automatic construction** - No manual tensor manipulation  
✅ **Professional output** - Organized data, metadata tracking  
✅ **Reproducible** - Hash-based indexing ensures consistency

**You've successfully run DMRG with TNCodebase!**

Now explore other examples to learn about:
- Custom model building
- Different initial states
- Time evolution (TDVP)
- Observable calculations
