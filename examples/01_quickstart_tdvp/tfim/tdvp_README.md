# TDVP Time Evolution

## Overview

This example demonstrates TDVP (Time-Dependent Variational Principle) time evolution using TNCodebase's config-driven workflow.

**What it does:**
- Starts with polarized initial state (all spins up)
- Evolves under TFIM Hamiltonian
- Uses TDVP algorithm for quantum dynamics
- Automatically saves data with hash-based indexing

**Prerequisites:** Package installed and activated

---

## Files

```
01_quickstart_tdvp/
├── tdvp_README.md              # This file
├── tdvp_config.json            # All simulation parameters
└── tdvp_run.jl            # Main script
```

---

## Usage

```bash
cd examples/01_quickstart_tdvp
julia run_tdvp.jl
```

The script will:
1. Load configuration from `tdvp_config.json`
2. Build the TFIM Hamiltonian (automatic)
3. Create polarized initial state (automatic)
4. Run TDVP time evolution for 200 sweeps
5. Save data to `data/` with automatic indexing (automatic)

---

## Understanding the Configuration

### Complete Structure

```json
{
  "system": {...},
  "model": {...},
  "state": {...},
  "algorithm": {
    "type": "tdvp",
    "solver": {...},
    "options": {...},
    "run": {...}
  }
}
```

---

## 1. System

```json
"system": {
  "type": "spin",
  "N": 20
}
```

**Parameters:**
- `type`: "spin" for spin-only systems
- `N`: Number of sites (20 spins)

---

## 2. Model

```json
"model": {
  "name": "transverse_field_ising",
  "params": {
    "N": 20,
    "J": -1.0,
    "h": 2.0,
    "coupling_dir": "Z",
    "field_dir": "X"
  }
}
```

**Hamiltonian:**
```
H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ
  = -1.0 × Σᵢ σᶻᵢσᶻᵢ₊₁ + 2.0 × Σᵢ σˣᵢ
```

**Parameters:**
- `J = -1.0`: Ferromagnetic coupling
- `h = 2.0`: Transverse field strength (strong field)
- `coupling_dir`: Coupling operators (Z)
- `field_dir`: Field direction (X)

See `examples/models/prebuilt_models/tfim/` for model details.

---

## 3. State

```json
"state": {
  "type": "prebuilt",
  "name": "polarized",
  "params": {
    "spin_direction": "Z",
    "eigenstate": 2
  }
}
```

**Initial state:** All spins up in Z direction (|↑↑↑...↑⟩)

**Parameters:**
- `spin_direction`: Which basis ("Z")
- `eigenstate`: 2 = highest eigenvalue (up state)

**This is a product state** (bond dimension χ = 1).

See `examples/states/prebuilt_states/spin_polarized/` for state details.

---

## 4. Algorithm

The algorithm section has three subsections:

### 4.1 Solver

```json
"solver": {
  "type": "krylov_exponential",
  "krylov_dim": 14,
  "tol": 1e-8,
  "evol_type":"real"
}
```

**Krylov exponential method** for time evolution operator exp(-iHt).

**Parameters:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `type` | "krylov_exponential" | Solver type |
| `krylov_dim` | 14 | Krylov subspace dimension |
| `tol` | 1e-8 | Convergence tolerance |
| `evol_type` | "real" | Evolution type: "real" or "imaginary" |


**Krylov dimension:**
- Approximates exp(-iHt) in Krylov subspace
- Larger → more accurate but slower
- 14 is a robust choice for most systems

**tolerance:**
- 1e-8 is standard, smaller the better, when tol = 0.0, the method becomes exact

**Evolution type:**
- `"real"`: Real-time evolution, applies exp(-iHt) — use for quench dynamics, spectral functions
- `"imaginary"`: Imaginary-time evolution, applies exp(-Ht) — use for cooling to ground state, finite temperature

### 4.2 Options

```json
"options": {
  "dt": 0.02,
  "chi_max": 100,
  "cutoff": 1e-8,
  "local_dim": 2
}
```

**Evolution parameters:**

| Parameter | Value | Description |
|-----------|-------|-------------|
| `dt` | 0.02 | Time step size |
| `chi_max` | 100 | Maximum bond dimension |
| `cutoff` | 1e-8 | Singular value cutoff |
| `local_dim` | 2 | Physical dimension (spin-1/2) |

**Time step (dt):**
- Controls accuracy vs speed
- Smaller → more accurate
- dt=0.02 is a reasonable choice

**Bond dimension (chi_max):**
- Hard limit on entanglement
- Prevents memory overflow
- Actual χ ≤ chi_max

**Cutoff:**
- Truncates small singular values
- Controls approximation quality
- 1e-8 is standard

### 4.3 Run

```json
"run": {
  "n_sweeps": 200
}
```

**Number of time steps:**
- Total evolution time: T = n_sweeps × dt = 200 × 0.02 = 4.0
- Each sweep is one time step

---

## The Core Function Call

The entire simulation runs with **one function call**:

```julia
state, run_id, run_dir = run_simulation_from_config(config, base_dir=data_dir)
```

**This function:**
1. Parses the configuration
2. Builds sites from system config
3. Builds MPO (Hamiltonian) from model config
4. Builds initial MPS from state config
5. Creates MPSState object
6. Runs TDVP evolution loop (200 time steps)
7. Saves checkpoints
8. Saves metadata
9. Returns final state and run info

**Everything is automated** - users only specify the config.

---

## Saved Data

Data is automatically saved to:

```
data/tdvp_[run_id]/
├── config.json            # Copy of configuration
├── metadata.json          # Evolution data
├── sweep_001.jld2        # State at t = 0.02
├── sweep_002.jld2        # State at t = 0.04
...
├── sweep_100.jld2        # State at t = 2.00
...
└── sweep_200.jld2        # Final state at t = 4.00
```

**Run ID format:** `YYYYMMDD_HHMMSS_[hash]`
- Timestamp: When simulation started
- Hash: First 8 chars of config hash
- Ensures reproducibility

**Metadata contains:**
- Sweep-by-sweep data (time, bond dimension)
- Configuration snapshot
- Convergence information

---

## Expected Behavior

### Initial State
- All spins aligned in Z (|↑↑↑...↑⟩)
- Bond dimension: χ = 1 (product state)
- Not an eigenstate of H

### During Evolution
- State evolves under H
- Bond dimension grows (entanglement builds)
- Spins rotate toward X direction (field direction)

---

## Modifying the Example

### Different Initial State

**Start with Neel state:**
```json
"state": {
  "type": "prebuilt",
  "name": "neel",
  "params": {
    "spin_direction": "Z",
    "even_state": 1,
    "odd_state": 2
  }
}
```

### Longer Evolution

**Increase time:**
```json
"run": {
  "n_sweeps": 500
}
```
Total time: T = 500 × 0.02 = 10.0

### Finer Time Resolution

**Smaller time step:**
```json
"options": {
  "dt": 0.01,
  ...
}
```
More steps for same total time.

## Parameter Selection Guide

### Time Step (dt)

**Choosing dt:**
- Too large: Evolution inaccurate
- Too small: Unnecessarily slow
- Start with dt = 0.01-0.05

**This example:** dt = 0.02 (balanced)

### Krylov Dimension

**Effect:**
- Larger → better approximation of exp(-iHt)
- Diminishing returns above ~15

**This example:** krylov_dim = 14 (robust)

### Bond Dimension (chi_max)

**Setting chi_max:**
- Monitor χ during evolution
- If χ → chi_max, increase chi_max
- Balance: accuracy vs memory

**This example:** chi_max = 100 (generous for N=20)

### Number of Sweeps

**Determining n_sweeps:**
- Depends on physics timescale
- Total time: T = n_sweeps × dt
- This example: T = 4.0 (several oscillation periods)

## Config-Driven Workflow Philosophy

TNCodebase uses a **fully config-driven approach**:

**User specifies:** JSON configuration file  
**Package handles:** All internal mechanics

**Benefits:**
- ✅ No code modification needed
- ✅ Complete reproducibility (config hash)
- ✅ Easy parameter exploration
- ✅ Automatic metadata tracking
- ✅ Professional data organization

**The `run_simulation_from_config()` function** abstracts:
- System construction
- Model building
- State preparation
- Algorithm execution
- Data management

This allows users to focus on physics, not implementation details.

---

## Troubleshooting

### Bond Dimension Saturates

**Symptom:** χ reaches chi_max during evolution

**Solution:**
```json
"options": {
  "chi_max": 150  // Increase from 100
}
```

### Slow Evolution

**Symptom:** Each sweep takes long time

**Possible causes:**
1. Large chi_max
2. Large krylov_dim
3. Small dt (many steps needed)

**Solutions:**
- Reduce chi_max if possible
- Reduce krylov_dim to 10-12
- Increase dt (if accuracy allows)

### Memory Issues

**Symptom:** Out of memory errors

**Solution:**
```json
"options": {
  "chi_max": 50  // Reduce from 100
}
```

## Summary

This example demonstrates TNCodebase's **config-driven workflow**:

✅ **Single configuration file** - All parameters in JSON  
✅ **One function call** - `run_simulation_from_config()`  
✅ **Automatic execution** - Building, evolution, saving  
✅ **Professional output** - Hash-indexed, metadata-tracked  
✅ **Fully reproducible** - Same config → same results

**The config-driven approach allows users to run complex tensor network simulations by specifying physics in JSON, while the package handles all implementation details.**
