# Long-Range Ising (Custom): TDVP Time Evolution

## Overview

Same physics as `long_range_ising/` but using **custom channels** instead of prebuilt template.

**Purpose:** Demonstrate custom channel definition for power-law interactions

---

## Files

```
long_range_ising_custom/
├── tdvp_README.md
├── tdvp_config.json
└── tdvp_run.jl
```

---

## Usage

```bash
cd examples/01_quickstart_tdvp/long_range_ising_custom
julia tdvp_run.jl
```

---

## Custom vs Prebuilt

### Prebuilt (long_range_ising/)

```json
"model": {
  "name": "long_range_ising",
  "params": {
    "N": 20, "J": 1.0, "alpha": 1.5, "n_exp": 8, "h": 0.5,
    "coupling_dir": "Z", "field_dir": "X"
  }
}
```

### Custom (this example)

```json
"model": {
  "name": "custom_spin",
  "params": {
    "N": 20,
    "dtype": "Float64",
    "channels": [
      {
        "type": "PowerLawCoupling",
        "op1": "Z", "op2": "Z",
        "strength": 1.0, "alpha": 1.5, "n_exp": 8, "N": 20
      },
      {
        "type": "Field",
        "op": "X", "strength": 0.5
      }
    ]
  }
}
```

**Same Hamiltonian, different specification method.**

---

## Hamiltonian

```
H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σˣᵢ
```

Built from two channels:
1. **PowerLawCoupling:** Long-range ZZ interaction
2. **Field:** Transverse X field

---

## Channel Reference

### PowerLawCoupling

```json
{
  "type": "PowerLawCoupling",
  "op1": "Z",
  "op2": "Z",
  "strength": 1.0,
  "alpha": 1.5,
  "n_exp": 8,
  "N": 20
}
```

| Parameter | Description |
|-----------|-------------|
| op1, op2 | Operators on sites i and j |
| strength | Coupling constant J |
| alpha | Power-law exponent α |
| n_exp | Number of exponentials for FSM |
| N | System size (required for FSM fitting) |

### Field

```json
{
  "type": "Field",
  "op": "X",
  "strength": 0.5
}
```

| Parameter | Description |
|-----------|-------------|
| op | Single-site operator |
| strength | Field strength h |

---

## When to Use Custom

**Use prebuilt when:**
- Standard long-range Ising
- Quick setup

**Use custom when:**
- Adding extra terms (NNN, fields in multiple directions)
- Combining power-law with other interactions
- Learning how models are constructed

---

## Variations

**1. Add longitudinal field:**
```json
{
  "type": "Field",
  "op": "Z",
  "strength": 0.2,
  "description": "Longitudinal field: hz * sum_i Z_i"
}
```

**2. Mixed interactions (ZZ long-range + XX short-range):**
```json
"channels": [
  {"type": "PowerLawCoupling", "op1": "Z", "op2": "Z", "strength": 1.0, "alpha": 1.5, "n_exp": 8, "N": 20},
  {"type": "FiniteRangeCoupling", "op1": "X", "op2": "X", "range": 1, "strength": 0.3},
  {"type": "Field", "op": "X", "strength": 0.5}
]
```

**3. Different power-law exponent:**
```json
"alpha": 3.0
```
Dipolar interactions (faster decay).

**4. Anisotropic long-range (different α for XX and ZZ):**
```json
"channels": [
  {"type": "PowerLawCoupling", "op1": "Z", "op2": "Z", "strength": 1.0, "alpha": 1.5, "n_exp": 8, "N": 20},
  {"type": "PowerLawCoupling", "op1": "X", "op2": "X", "strength": 0.5, "alpha": 2.5, "n_exp": 8, "N": 20},
  {"type": "Field", "op": "X", "strength": 0.5}
]
```

---

## Output

Same as prebuilt version:
```
data/tdvp_[run_id]/
├── config.json
├── metadata.json
├── sweep_001.jld2
...
└── sweep_250.jld2
```

---
