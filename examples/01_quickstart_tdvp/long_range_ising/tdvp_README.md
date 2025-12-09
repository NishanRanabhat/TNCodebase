# Long-Range Ising: TDVP Time Evolution

## Overview

Time evolution of a domain wall under long-range Ising interactions using TDVP.

**Physics:** Domain spreading with power-law 1/r^α interactions  
**Initial state:** Localized domain (flipped spins in center)  

---

## Files

```
long_range_ising/
├── tdvp_README.md
├── tdvp_config.json
└── tdvp_run.jl
```

---

## Usage

```bash
cd examples/01_quickstart_tdvp/long_range_ising
julia tdvp_run.jl
```

---

## Physics

### Hamiltonian

```
H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σˣᵢ
```

**Parameters:**
- J = 1.0: Antiferromagnetic coupling
- α = 1.5: Power-law exponent
- h = 0.5: Transverse field
- n_exp = 10: FSM exponentials (for efficient MPO)

### Initial State

Domain state: `↓↓↓...↓↓↑↑↑↑↓↓...↓↓↓`
- Background: spin down (base_state = 1)
- Domain: 4 flipped spins at center (sites 8-11)
- Bond dimension: χ = 1 (product state)

---

## Configuration

### Model

```json
"model": {
  "name": "long_range_ising",
  "params": {
    "N": 20,
    "J": 1.0,
    "alpha": 1.5,
    "n_exp": 8,
    "h": 0.5,
    "coupling_dir": "Z",
    "field_dir": "X"
  }
}
```

### State

```json
"state": {
  "type": "prebuilt",
  "name": "domain",
  "params": {
    "spin_direction": "Z",
    "start_index": 8,
    "domain_size": 4,
    "base_state": 1,
    "flip_state": 2
  }
}
```

### Algorithm

```json
"algorithm": {
  "type": "tdvp",
  "solver": {"type": "krylov_exponential", "krylov_dim": 8, "tol": 1e-8, "evol_type": "real"},
  "options": {"dt": 0.02, "chi_max": 60, "cutoff": 1e-8},
  "run": {"n_sweeps": 200}
}
```

---

## Parameter Guide

### Power-law exponent (α)

| α | Regime | Spreading |
|---|--------|-----------|
| α < 1 | Very long-range | Nearly instantaneous |
| α = 1.5 | Intermediate | Power-law light cone |
| α = 3 | Dipolar | Slower spreading |
| α > 3 | Short-range-like | Linear light cone |

### FSM exponentials (n_exp)

- Controls MPO accuracy for power-law
- Rule of thumb: n_exp ≈ log(N) + 5
- N = 20 → n_exp = 8 works well

### Bond dimension (chi_max)

- Long-range models build entanglement faster
- chi_max = 60 gives headroom for N = 20
- Monitor if χ saturates during evolution

## Output

Data saved to:
```
data/tdvp_[run_id]/
├── config.json
├── metadata.json
├── sweep_001.jld2
...
└── sweep_200.jld2
```

---

## Troubleshooting

**Bond dimension saturates:**
- Increase chi_max to 150-200
- Long-range interactions generate more entanglement

**Slow evolution:**
- Reduce n_exp (trades accuracy for speed)
- Increase dt if accuracy allows

**Inaccurate long-range:**
- Increase n_exp to 12-14
- Check FSM approximation quality

---

