# Prebuilt State Templates

## Overview

This directory contains examples using TNCodebase's **prebuilt state templates**. These templates provide simple configurations for common initial states used in MPS (TDVP and DMRG) simulations.

**What are initial states?**
- Starting point for DMRG, TDVP, and other MPS algorithms
- Can significantly affect convergence speed
- Choice depends on expected ground state or dynamics

**Types available:**
- **Product states:** Bond dimension χ = 1 (polarized, neel, kink, domain)
- **Random states:** Bond dimension χ = user-specified (random initialization)

---

## Available Templates

TNCodebase provides **5 prebuilt state templates**:

### Product States (χ = 1)

1. **polarized** - All sites in same eigenstate
2. **neel** - Alternating pattern between two eigenstates
3. **kink** - Domain wall (left region | right region)
4. **domain** - Localized region of flipped spins

### Random States (χ > 1)

5. **random** - Random MPS with specified bond dimension

**Note:** Templates 1-4 work for both spin-only and spin-boson systems. Template 5 works for both.

---

## Understanding the Label System

### Spin Labels

Spins are specified by **(direction, eigenstate)**:

**Direction:**
- `"X"`, `"Y"`, or `"Z"` - Which operator's eigenbasis

**Eigenstate:**
- `1` - Lowest eigenvalue eigenvector
- `2` - Highest eigenvalue eigenvector

**For spin-1/2:**
- Z direction: 1 = |↓⟩, 2 = |↑⟩
- X direction: 1 = |→⟩, 2 = |←⟩
- Y direction: 1 = |⊙⟩, 2 = |⊗⟩

### Boson Labels

Bosons are specified by **Fock state n**:
- `0` - Vacuum |0⟩
- `1` - One photon/phonon |1⟩
- `n` - n photons/phonons |n⟩

Must satisfy: `0 ≤ n ≤ nmax`

---

## Template 1: polarized

### Description

All sites in the same eigenstate. Creates a uniform product state.

**Spin-only:** All spins aligned in chosen direction  
**Spin-boson:** Boson in Fock state + all spins aligned

### Configuration

**Spin-only:**
```json
{
  "system": {"type": "spin", "N": 20, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "polarized",
    "params": {
      "spin_direction": "Z",
      "eigenstate": 2
    }
  }
}
```

**Spin-boson:**
```json
{
  "system": {"type": "spinboson", "N_spins": 20, "nmax": 5, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "polarized",
    "params": {
      "boson_level": 0,
      "spin_direction": "Z",
      "spin_eigenstate": 2
    }
  }
}
```

### Parameters

**Spin-only:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `spin_direction` | String | No | "Z" | Eigenbasis direction ("X", "Y", "Z") |
| `eigenstate` | Int | No | 2 | Which eigenstate (1=lowest, 2=highest) |

**Spin-boson:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `boson_level` | Int | No | 0 | Fock state n (0 ≤ n ≤ nmax) |
| `spin_direction` | String | No | "Z" | Spin eigenbasis direction |
| `spin_eigenstate` | Int | No | 2 | Spin eigenstate (1 or 2) |

### What It Creates

**Spin-only (N=5):**
```
Site 1: (Z, 2)  →  |↑⟩
Site 2: (Z, 2)  →  |↑⟩
Site 3: (Z, 2)  →  |↑⟩
Site 4: (Z, 2)  →  |↑⟩
Site 5: (Z, 2)  →  |↑⟩
```

**Spin-boson (N_spins=3, n=0):**
```
Site 1: 0       →  |0⟩_boson
Site 2: (Z, 2)  →  |↑⟩
Site 3: (Z, 2)  →  |↑⟩
Site 4: (Z, 2)  →  |↑⟩
```

### Parameter Examples

**All spins up (Z):**
```json
"spin_direction": "Z", "eigenstate": 2
```

**All spins down (Z):**
```json
"spin_direction": "Z", "eigenstate": 1
```

**All spins right (X):**
```json
"spin_direction": "X", "eigenstate": 2
```

**Boson vacuum + spins up:**
```json
"boson_level": 0, "spin_direction": "Z", "spin_eigenstate": 2
```

### When to Use

- TFIM in ordered phase (all spins aligned with field)
- Ferromagnetic ground state guess
- Simple starting state for testing

---

## Template 2: neel

### Description

Alternating pattern between two eigenstates. Creates antiferromagnetic-like configuration.

**Spin-only:** Alternating spin pattern  
**Spin-boson:** Boson in Fock state + alternating spin pattern

### Configuration

**Spin-only:**
```json
{
  "system": {"type": "spin", "N": 20, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "neel",
    "params": {
      "spin_direction": "Z",
      "even_state": 1,
      "odd_state": 2
    }
  }
}
```

**Spin-boson:**
```json
{
  "system": {"type": "spinboson", "N_spins": 20, "nmax": 5, "S": 0.5},
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

**Spin-only:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `spin_direction` | String | No | "Z" | Eigenbasis direction ("X", "Y", "Z") |
| `even_state` | Int | No | 1 | Eigenstate for even sites |
| `odd_state` | Int | No | 2 | Eigenstate for odd sites |

**Spin-boson:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `boson_level` | Int | No | 0 | Fock state n |
| `spin_direction` | String | No | "Z" | Spin eigenbasis direction |
| `even_state` | Int | No | 1 | Eigenstate for even sites |
| `odd_state` | Int | No | 2 | Eigenstate for odd sites |

### What It Creates

**Spin-only (N=5):**
```
Site 1: (Z, 2)  →  |↑⟩  (odd)
Site 2: (Z, 1)  →  |↓⟩  (even)
Site 3: (Z, 2)  →  |↑⟩  (odd)
Site 4: (Z, 1)  →  |↓⟩  (even)
Site 5: (Z, 2)  →  |↑⟩  (odd)
```

**Pattern:** odd sites get `odd_state`, even sites get `even_state`

### Parameter Examples

**Standard Neel (↑↓↑↓):**
```json
"spin_direction": "Z", "even_state": 1, "odd_state": 2
```

**Inverted Neel (↓↑↓↑):**
```json
"spin_direction": "Z", "even_state": 2, "odd_state": 1
```

**X-basis alternating:**
```json
"spin_direction": "X", "even_state": 1, "odd_state": 2
```

### When to Use

- Heisenberg/XXZ antiferromagnetic ground state guess
- Most common DMRG starting state
- Systems with nearest-neighbor antiferromagnetic coupling

---

## Template 3: kink

### Description

Domain wall state: left region in one state, right region in another.

**Creates two domains separated at specified position.**

### Configuration

**Spin-only:**
```json
{
  "system": {"type": "spin", "N": 10, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "kink",
    "params": {
      "spin_direction": "Z",
      "position": 5,
      "left_state": 1,
      "right_state": 2
    }
  }
}
```

**Spin-boson:**
```json
{
  "system": {"type": "spinboson", "N_spins": 10, "nmax": 5, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "kink",
    "params": {
      "boson_level": 0,
      "spin_direction": "Z",
      "position": 5,
      "left_state": 1,
      "right_state": 2
    }
  }
}
```

### Parameters

**Spin-only:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `spin_direction` | String | No | "Z" | Eigenbasis direction |
| `position` | Int | Yes | - | Kink position (1 ≤ position < N) |
| `left_state` | Int | No | 1 | Eigenstate for left region |
| `right_state` | Int | No | 2 | Eigenstate for right region |

**Spin-boson:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `boson_level` | Int | No | 0 | Fock state n |
| `spin_direction` | String | No | "Z" | Spin eigenbasis direction |
| `position` | Int | Yes | - | Kink position |
| `left_state` | Int | No | 1 | Left region eigenstate |
| `right_state` | Int | No | 2 | Right region eigenstate |

### What It Creates

**Spin-only (N=8, position=4):**
```
Site 1: (Z, 1)  →  |↓⟩  (left)
Site 2: (Z, 1)  →  |↓⟩  (left)
Site 3: (Z, 1)  →  |↓⟩  (left)
Site 4: (Z, 1)  →  |↓⟩  (left)
Site 5: (Z, 2)  →  |↑⟩  (right)  ← kink here
Site 6: (Z, 2)  →  |↑⟩  (right)
Site 7: (Z, 2)  →  |↑⟩  (right)
Site 8: (Z, 2)  →  |↑⟩  (right)
```

**Pattern:** Sites 1 to `position` get `left_state`, sites `position+1` to N get `right_state`

### Parameter Examples

**Domain wall at center:**
```json
"position": 10  // For N=20
```

**Domain wall at quarter:**
```json
"position": 5   // For N=20
```

### When to Use

- Domain wall dynamics
- Studying excitations propagating from interface
- Symmetry-breaking configurations

---

## Template 4: domain

### Description

Localized region of flipped spins within a uniform background. Creates a "bubble" or "domain" of opposite polarization.

### Configuration

**Spin-only:**
```json
{
  "system": {"type": "spin", "N": 10, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "domain",
    "params": {
      "spin_direction": "Z",
      "start_index": 5,
      "domain_size": 2,
      "base_state": 1,
      "flip_state": 2
    }
  }
}
```

**Spin-boson:**
```json
{
  "system": {"type": "spinboson", "N_spins": 10, "nmax": 5, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "domain",
    "params": {
      "boson_level": 0,
      "spin_direction": "Z",
      "start_index": 5,
      "domain_size": 2,
      "base_state": 1,
      "flip_state": 2
    }
  }
}
```

### Parameters

**Spin-only:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `spin_direction` | String | No | "Z" | Eigenbasis direction |
| `start_index` | Int | Yes | - | Where domain starts (1 ≤ start_index ≤ N) |
| `domain_size` | Int | Yes | - | Number of flipped spins |
| `base_state` | Int | No | 1 | Background eigenstate |
| `flip_state` | Int | No | 2 | Domain eigenstate |

**Spin-boson:**

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `boson_level` | Int | No | 0 | Fock state n |
| `spin_direction` | String | No | "Z" | Spin eigenbasis direction |
| `start_index` | Int | Yes | - | Domain start position |
| `domain_size` | Int | Yes | - | Domain size |
| `base_state` | Int | No | 1 | Background eigenstate |
| `flip_state` | Int | No | 2 | Domain eigenstate |

### What It Creates

**Spin-only (N=10, start_index=5, domain_size=2):**
```
Site 1: (Z, 1)  →  |↓⟩  (background)
Site 2: (Z, 1)  →  |↓⟩  (background)
Site 3: (Z, 1)  →  |↓⟩  (background)
Site 4: (Z, 1)  →  |↓⟩  (background)
Site 5: (Z, 2)  →  |↑⟩  (domain start)
Site 6: (Z, 2)  →  |↑⟩  (domain)
Site 7: (Z, 1)  →  |↓⟩  (background)
Site 8: (Z, 1)  →  |↓⟩  (background)
Site 9: (Z, 1)  →  |↓⟩  (background)
Site 10: (Z, 1) →  |↓⟩  (background)
```

**Pattern:** Background of `base_state` with localized `domain_size` spins in `flip_state`

### Parameter Examples

**Single spin flip at center:**
```json
"start_index": 10, "domain_size": 1  // For N=20
```

**Three flipped spins:**
```json
"start_index": 8, "domain_size": 3
```

**Domain wraps to end if needed:**
```json
"start_index": 18, "domain_size": 5  // For N=20, wraps to site 20
```

### When to Use

- Localized spin-flip excitations
- Magnon/soliton initial states
- Studying dynamics of localized disturbances

---

## Template 5: random

### Description

Random MPS with specified bond dimension. Non-product state (χ > 1).

**Works for both spin-only and spin-boson systems.**

### Configuration

**Spin-only:**
```json
{
  "system": {"type": "spin", "N": 20, "S": 0.5},
  "state": {
    "type": "random",
    "params": {
      "bond_dim": 10
    }
  }
}
```

**Spin-boson:**
```json
{
  "system": {"type": "spinboson", "N_spins": 20, "nmax": 5, "S": 0.5},
  "state": {
    "type": "random",
    "params": {
      "bond_dim": 10
    }
  }
}
```

### Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `bond_dim` | Int | No | 10 | Bond dimension χ |

### What It Creates

**Random MPS structure:**
```
Site 1: [1 × d × χ]       (left edge)
Site 2: [χ × d × χ]       (bulk)
...
Site N-1: [χ × d × χ]     (bulk)
Site N: [χ × d × 1]       (right edge)
```

**Bond dimensions:** All internal bonds have dimension χ

### Parameter Examples

**Small bond dimension (faster):**
```json
"bond_dim": 5
```

**Medium bond dimension (balanced):**
```json
"bond_dim": 20
```

**Large bond dimension (expensive but thorough):**
```json
"bond_dim": 50
```

### When to Use

- No good guess for ground state
- Testing DMRG convergence
- Avoiding bias from product state guess
- High entanglement expected

---

## Quick Reference Table

| Template | Type | Bond Dim | System Types | Common Use |
|----------|------|----------|--------------|------------|
| `polarized` | Product | 1 | Spin, SpinBoson | Ferromagnetic, ordered phase |
| `neel` | Product | 1 | Spin, SpinBoson | Antiferromagnetic, most common |
| `kink` | Product | 1 | Spin, SpinBoson | Domain wall dynamics |
| `domain` | Product | 1 | Spin, SpinBoson | Localized excitations |
| `random` | Random | χ | Spin, SpinBoson | No good guess, testing |

---

## State Type Selection Guide

### Choose Based on Expected Ground State

**For ferromagnetic systems (J < 0):**
- Use `polarized` with all spins aligned

**For antiferromagnetic systems (J > 0):**
- Use `neel` with alternating pattern

**For transverse field Ising (large h):**
- Use `polarized` in field direction (usually X)

**For unknown/complex systems:**
- Use `random` to avoid bias
- May need higher bond_dim

### Choose Based on Dynamics Study

**For domain wall propagation:**
- Use `kink` with appropriate position

**For localized excitations:**
- Use `domain` with appropriate size

**For quench dynamics:**
- Use ground state of pre-quench Hamiltonian

---

## Usage Pattern

### 1. Create Config File

Choose template and set parameters:
```json
{
  "system": {"type": "spin", "N": 20, "S": 0.5},
  "state": {
    "type": "prebuilt",
    "name": "neel",
    "params": {
      "spin_direction": "Z",
      "even_state": 1,
      "odd_state": 2
    }
  }
}
```

### 2. Build State

```julia
using TNCodebase
using JSON

config = JSON.parsefile("config.json")
mps = build_mps_from_config(config)
```

### 3. Use in Simulation

```julia
# With model
mpo = build_mpo_from_config(model_config)

# Create state object
state = MPSState(mps, mpo)

# Run DMRG
result = dmrg!(state, dmrg_config)
```

---

## Architecture Notes

### Product States (χ = 1)

**Structure:**
- Each tensor is [1 × d × 1]
- No entanglement between sites
- Exact representation as tensor product
- Very small memory footprint

**Advantages:**
- Fast to create
- Small memory (few KB)
- Good starting point if close to ground state

**Limitations:**
- Can't represent entangled states
- May take more DMRG sweeps to converge
- Poor choice if ground state highly entangled

### Random States (χ > 1)

**Structure:**
- Internal bonds have dimension χ
- Can represent entangled states
- Random tensor entries

**Advantages:**
- No bias from initial guess
- Can represent more complex states
- Better for high-entanglement systems

**Limitations:**
- Larger memory (~χ² scaling)
- More expensive to create
- May take longer to converge overall

### Bond Dimension Selection

**For random states:**
- χ = 10-20: Light entanglement
- χ = 20-50: Moderate entanglement
- χ = 50-100: Heavy entanglement

**Note:** DMRG will grow bond dimension during sweeps, so initial χ doesn't need to match final χ_max.

---

## Examples in This Directory

### Prebuilt Product States

**spin/polarized/**
- Simple polarized state example
- Shows basic template usage

**spin/neel/**
- Alternating pattern example
- Most common DMRG starting state

**spinboson/vacuum_neel/**
- Spin-boson system example
- Boson vacuum + Neel spins

### Random States

**random/**
- Random MPS initialization
- Shows bond dimension parameter

---

## See Also

- **Custom states:** `examples/states/custom_states/` (site-by-site specification)
- **State documentation:** `docs/state_building.md`
- **Model templates:** `examples/models/prebuilt_models/`
- **Quickstart:** `examples/00_quickstart/`

---

## Summary

TNCodebase provides **5 prebuilt state templates**:
- ✅ **Product states** (polarized, neel, kink, domain) - χ = 1
- ✅ **Random states** (random) - χ = user-specified
- ✅ Works for both **spin-only** and **spin-boson** systems
- ✅ Simple configuration via JSON

**For most DMRG simulations, use `neel` for antiferromagnetic or `polarized` for ferromagnetic starting states.**
