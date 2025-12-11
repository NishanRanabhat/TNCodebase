# Future Architecture: Geometry-Agnostic Channels

**Date:** December 2024  
**Status:** Planning (not blocking current work)  
**Priority:** Implement when adding new species (fermions, multi-boson, etc.)

---

## The Problem in Simple Terms

Right now, your code mixes two separate ideas into one:

1. **Geometry** — How do sites talk to each other? (nearest-neighbor, power-law, all-to-all)
2. **Species** — What kind of particle lives on the site? (spin, boson, fermion)

For example, `FiniteRangeCoupling` is labeled as a "Spin" channel:

```julia
struct FiniteRangeCoupling <: Spin  # ← "Spin" is baked into the type
```

But there's nothing spin-specific about "two sites coupling at fixed range." A fermion-fermion nearest-neighbor hopping has the exact same geometry.

---

## Why This Matters

### Current: Adding fermions requires duplication

```julia
# You'd need separate structs for each species
struct SpinFiniteRangeCoupling <: Spin ... end
struct FermionFiniteRangeCoupling <: Fermion ... end
struct BosonFiniteRangeCoupling <: Boson ... end

# Same geometry, copy-pasted 3 times
```

### Future: One geometry, many species

```julia
# Geometry is species-agnostic
struct FiniteRangeCoupling <: Channel
    species_a::Symbol    # :spin, :fermion, :boson
    op_a::Symbol         # :Z, :cdag, :a, etc.
    species_b::Symbol
    op_b::Symbol
    range::Int
    strength::Float64
end

# Same struct works for all
FiniteRangeCoupling(:spin, :Z, :spin, :Z, 1, 1.0)      # spin-spin
FiniteRangeCoupling(:fermion, :cdag, :fermion, :c, 1, 1.0)  # hopping
```

---

## What's Hardcoded Now (The Debt)

### 1. FSM assumes fixed site layout

In `Core_fsm.jl`, spinboson models assume:
- Site 1 = boson (always)
- Sites 2 to N = spins (always)

```julia
# L tensor (site 1) gets boson operators
# Bulk tensors (sites 2...N) get spin operators
```

This breaks if you want:
- Boson in the middle
- Multiple bosons
- Mixed spin-fermion chains

### 2. Channel types define species

```julia
abstract type Spin <: Channel end      # channels for spin models
abstract type SpinBoson <: Channel end # channels for spinboson models
```

Species is in the type hierarchy, not in the data.

### 3. MPO builder dispatches on channel type

```julia
build_mpo(fsm::SpinFSMPath; ...)       # for spin
build_mpo(fsm::SpinBosonFSMPath; ...)  # for spinboson
```

Each new species combo needs a new FSM type and new dispatch.

---

## The Clean Architecture

### Principle: Geometry is data, Species is data

```julia
# Geometry structs (no species baked in)
abstract type Channel end

struct FiniteRangeCoupling <: Channel
    species_a::Symbol
    op_a::Symbol
    species_b::Symbol  
    op_b::Symbol
    range::Int
    strength::Float64
end

struct Field <: Channel
    species::Symbol
    op::Symbol
    strength::Float64
end

struct PowerLawCoupling <: Channel
    species_a::Symbol
    op_a::Symbol
    species_b::Symbol
    op_b::Symbol
    strength::Float64
    alpha::Float64
    n_exp::Int
end
```

### Site layout is explicit input

```julia
# User specifies what lives where
sites = [:boson, :spin, :spin, :spin, :spin, :fermion, :fermion]

# FSM figures out where to put operators
build_mpo(channels, sites)
```

### Operator resolution at build time

```julia
# Operator dictionaries per species
spin_ops    = Dict(:X => [...], :Y => [...], :Z => [...])
boson_ops   = Dict(:a => [...], :adag => [...], :n => [...])
fermion_ops = Dict(:c => [...], :cdag => [...], :n => [...])

# Build time: look up species → get operator matrix
function get_operator(species::Symbol, op::Symbol, site_info)
    if species == :spin
        return spin_ops[op]
    elseif species == :boson
        return boson_ops[op]
    elseif species == :fermion
        return fermion_ops[op]  # with Jordan-Wigner handled
    end
end
```

---

## Multi-Species Example

### Spin-Boson-Fermion Model

```
H = J Σᵢ ZᵢZᵢ₊₁ + ω b†b + g(a+a†)Σᵢ Xᵢ + t Σᵢ (c†ᵢcᵢ₊₁ + h.c.) + V Σᵢ nᵢZᵢ
    \_________/   \___/   \__________/   \____________________/   \_______/
    spin-spin    boson    spin-boson      fermion hopping      fermion-spin
```

### Config

```json
{
  "sites": ["boson", "spin", "spin", "spin", "fermion", "fermion"],
  "channels": [
    {"type": "FiniteRangeCoupling", "species_a": "spin", "op_a": "Z", 
     "species_b": "spin", "op_b": "Z", "range": 1, "strength": 1.0},
    
    {"type": "Field", "species": "boson", "op": "n", "strength": 1.0},
    
    {"type": "CollectiveCoupling", "species_a": "boson", "op_a": "x",
     "species_b": "spin", "op_b": "X", "strength": 0.2},
    
    {"type": "FiniteRangeCoupling", "species_a": "fermion", "op_a": "cdag",
     "species_b": "fermion", "op_b": "c", "range": 1, "strength": 1.0},
    
    {"type": "LocalCoupling", "species_a": "fermion", "op_a": "n",
     "species_b": "spin", "op_b": "Z", "strength": 0.5}
  ]
}
```

### FSM builds based on site layout

```julia
function build_FSM(channels, sites)
    # For each channel:
    # 1. Find which sites have species_a
    # 2. Find which sites have species_b
    # 3. Build transitions between those sites
    # 4. Operator matrices resolved from species dictionaries
end
```

---

## Work Required

### Phase 1: Refactor Channel Types

| Current | New |
|---------|-----|
| `struct Field <: Spin` | `struct Field <: Channel` with `species::Symbol` |
| `struct FiniteRangeCoupling <: Spin` | `struct FiniteRangeCoupling <: Channel` with `species_a`, `species_b` |
| etc. | etc. |

### Phase 2: Refactor FSM

| Current | New |
|---------|-----|
| Hardcoded boson at site 1 | Site layout as input |
| Separate `SpinFSMPath`, `SpinBosonFSMPath` | Single `FSMPath` type |
| Species in type dispatch | Species in data |

### Phase 3: Refactor MPO Builder

| Current | New |
|---------|-----|
| `build_mpo(::SpinFSMPath)` | `build_mpo(fsm, sites)` |
| `build_mpo(::SpinBosonFSMPath)` | Same function, site-aware |
| Hardcoded local dimensions | Per-site local dimension lookup |

### Phase 4: Update Modelbuilder

| Current | New |
|---------|-----|
| `custom_spin`, `custom_spinboson` | Single `custom` model type |
| Species implicit in model name | Explicit `sites` array in config |

---

## What Works Today (Don't Break This)

The current code works perfectly for:
- Pure spin chains
- Spinboson with boson at site 1

Don't refactor until you need:
- Fermions
- Multiple bosons
- Boson not at site 1
- Mixed arbitrary species

---

## Summary

| Concept | Current | Future |
|---------|---------|--------|
| Species | Baked into type hierarchy | Data field in struct |
| Geometry | Mixed with species | Pure geometry structs |
| Site layout | Hardcoded | Explicit input |
| Adding new species | New types + new dispatch | Just new operator dictionary |

**Bottom line:** Geometry and species are orthogonal. Current code conflates them. Future refactor separates them. Do it when adding fermions, not before.

---

## Quick Reference: Geometry Types

| Geometry | Sites | Description |
|----------|-------|-------------|
| `Field` | 1 | Single-site operator |
| `FiniteRangeCoupling` | 2 | Fixed range two-site |
| `PowerLawCoupling` | 2 | 1/r^α two-site |
| `ExpChannelCoupling` | 2 | Exponential decay two-site |
| `CollectiveCoupling` | all | One site couples to all of another species |
| `LocalCoupling` | 2 | On-site interspecies coupling |

All of these are species-agnostic. Species is just a label that gets resolved at build time.
