# Prebuilt Long-Range Ising Template

## Overview

Example using the `long_range_ising` prebuilt template with automatic FSM decomposition.

**Hamiltonian:** H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σˣᵢ

---

## Using the Template

### Configuration

```json
{
  "model": {
    "name": "long_range_ising",
    "params": {
      "N": 30,
      "J": 1.0,
      "alpha": 1.5,
      "n_exp": 10,
      "h": 0.0,
      "coupling_dir": "Z",
      "field_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### What It Creates

The template automatically:
1. Recognizes power-law interaction (1/r^α)
2. Applies FSM decomposition
3. Builds 2 channels:
   - `PowerLawCoupling(Z, Z, strength=J, alpha=α, n_exp=K, N=N)`
   - `Field(X, strength=h)`

**Result:** Bond dimension χ ~ K (independent of N!)

---

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N` | Int | Yes | - | Number of sites |
| `J` | Float | Yes | - | Coupling strength |
| `alpha` | Float | Yes | - | Power-law exponent α |
| `n_exp` | Int | Yes | - | Number of exponentials (K) |
| `h` | Float | No | 0.0 | Field strength |
| `coupling_dir` | String | No | "Z" | Coupling operators ("X", "Y", "Z") |
| `field_dir` | String | No | "X" | Field operator ("X", "Y", "Z") |
| `dtype` | String | No | "Float64" | Data type |

### Parameter Guide

**alpha (power-law exponent):**
- α < 1: Very long-range
- α = 1.5: Intermediate (this example)
- α = 3: Dipolar interactions
- α > 3: Approaching short-range

**n_exp (number of exponentials):**
- Controls FSM accuracy vs bond dimension
- Larger → more accurate, larger χ
- Rule of thumb: `n_exp ~ log(N) + 5`
- For N=30: n_exp=10 works well
- For N=100: n_exp=12-15 works well

### Parameter Examples

**Intermediate range:**
```json
"J": 1.0, "alpha": 1.5, "n_exp": 10
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/|i-j|^1.5

**Dipolar:**
```json
"J": 1.0, "alpha": 3.0, "n_exp": 10
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/|i-j|³

**Very long-range:**
```json
"J": 1.0, "alpha": 0.5, "n_exp": 12
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/√|i-j|

**With field:**
```json
"J": 1.0, "alpha": 1.5, "n_exp": 10, "h": 0.5
```
→ H = Σᵢ<ⱼ ZᵢZⱼ/|i-j|^1.5 + 0.5Σᵢ Xᵢ

---

## Usage

```bash
cd examples/models/prebuilt/long_range_ising
julia inspect_model.jl
```

**Output:**
```
Prebuilt Long-Range Ising Template

Parameters:
  α = 1.5, K = 10

MPO Structure:
  Maximum χ = 12

FSM Efficiency:
  Reduction: 2.5× (vs naive χ≈30)
```

---

## FSM Efficiency

**Bond dimension scaling:**
- With FSM: χ ~ K (this template)
- Without FSM: χ ~ N

**For N=30, K=10:**
- χ_FSM = 12
- χ_naive ≈ 30
- **Reduction: 2.5×**

**For larger systems, gain is much larger!**

---

## See Also

- **Custom FSM:** `examples/models/custom/advanced_fsm/` (see FSM construction)
- **All templates:** `examples/models/prebuilt/README.md`
- **Documentation:** `docs/model_building.md`
