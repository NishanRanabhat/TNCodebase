# Prebuilt TFIM Template

## Overview

Example using the `transverse_field_ising` prebuilt template.

**Hamiltonian:** H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ

---

## Using the Template

### Configuration

```json
{
  "model": {
    "name": "transverse_field_ising",
    "params": {
      "N": 20,
      "J": -1.0,
      "h": 0.5,
      "coupling_dir": "Z",
      "field_dir": "X",
      "dtype": "Float64"
    }
  }
}
```

### What It Creates

The template automatically builds 2 channels:
1. `FiniteRangeCoupling(Z, Z, range=1, strength=J)`
2. `Field(X, strength=h)`

---

## Parameters

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `N` | Int | Yes | - | Number of sites |
| `J` | Float | Yes | - | Coupling strength |
| `h` | Float | Yes | - | Field strength |
| `coupling_dir` | String | No | "Z" | Coupling operators ("X", "Y", "Z") |
| `field_dir` | String | No | "X" | Field operator ("X", "Y", "Z") |
| `dtype` | String | No | "Float64" | Data type |

### Parameter Examples

**Standard TFIM:**
```json
"J": -1.0, "h": 0.5, "coupling_dir": "Z", "field_dir": "X"
```
→ H = -Σᵢ ZᵢZᵢ₊₁ + 0.5 Σᵢ Xᵢ

**Antiferromagnetic:**
```json
"J": 1.0, "h": 0.5, "coupling_dir": "Z", "field_dir": "X"
```
→ H = Σᵢ ZᵢZᵢ₊₁ + 0.5 Σᵢ Xᵢ

**Different basis:**
```json
"J": -1.0, "h": 0.5, "coupling_dir": "X", "field_dir": "Z"
```
→ H = -Σᵢ XᵢXᵢ₊₁ + 0.5 Σᵢ Zᵢ

---

## Usage

```bash
cd examples/models/prebuilt/tfim
julia inspect_model.jl
```

**Output:**
```
Prebuilt TFIM Template

Parameters:
  J = -1.0, h = 0.5

MPO Structure:
  Maximum χ = 5
```

---

## See Also

- **Custom TFIM:** `examples/models/custom/tfim/` (build from channels)
- **All templates:** `examples/models/prebuilt/README.md`
- **Documentation:** `docs/model_building.md`
