# Spin-Boson Long-Range Model: Ising-Dicke

## Overview

**Advanced spin-boson example with long-range interactions.**

This example demonstrates how to build a sophisticated spin-boson model from scratch using TNCodebase's channel system. It combines:
- **Heterogeneous sites** (1 boson + N spins)
- **Long-range power-law interactions** (via FSM)
- **Tavis-Cummings light-matter coupling** (correct Sp/Sm operators)
- **Complete channel flexibility**

**Complexity:** Advanced  
**Runtime:** ~10 seconds  
**Prerequisites:** Understanding of quantum optics helpful

---

## The Physics

### Hamiltonian

```
H = ω b†b + J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + g Σᵢ (a σ⁺ᵢ + a† σ⁻ᵢ)
```

### Physical Components

**1. Boson Energy: ω b†b**
- Harmonic oscillator (photon mode or phonon mode)
- Frequency ω sets energy scale
- Truncated at nmax photons/phonons

**2. Long-Range Ising: J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α**
- Power-law interaction between spins
- α controls interaction range:
  - α ≈ 0: Coulomb (unscreened)
  - α = 1.5: This example
  - α = 3: Dipolar
- **Uses FSM for efficiency!** (Bond dim ~12 instead of ~N)

**3. Tavis-Cummings Coupling: g Σᵢ (a σ⁺ᵢ + a† σ⁻ᵢ)**
- Collective light-matter interaction
- **a σ⁺ᵢ:** Photon absorbed, spin raised |↓⟩ → |↑⟩
- **a† σ⁻ᵢ:** Photon emitted, spin lowered |↑⟩ → |↓⟩
- Conserves total excitations (N_photons + N_up-spins)
- **This is the CORRECT Jaynes-Cummings/Tavis-Cummings form**

---

## Why This Hamiltonian?

### Physical Systems

**Trapped Ions:**
- Coulomb interaction (α ≈ 0) between ions
- Phonon modes couple to internal states
- g = Lamb-Dicke coupling
- Experiments: Monroe group, Wineland group

**Cavity QED:**
- Rydberg atoms in optical cavity
- Dipolar interactions (α = 3) between atoms
- Photon mode couples to atomic transitions
- Experiments: Kimble group, Rempe group

**Circuit QED:**
- Superconducting qubits in microwave resonator
- Capacitive coupling between qubits
- Resonator mediates interactions
- Experiments: Schoelkopf group, Devoret group

**Cold Atoms:**
- Dipolar gases in optical cavity
- Long-range interactions + cavity-mediated coupling
- Quantum phase transitions
- Experiments: Esslinger group

### Key Phenomena

**Long-Range Order:**
- Power-law interactions create long-range correlations
- Competition between Ising order and TC coupling
- Rich phase diagrams

**Cavity-Mediated Interactions:**
- Spins interact via virtual photon exchange
- Effective spin-spin interaction ∝ g²/ω
- Long-range even without direct power-law

---

## Mathematical Details

### Tavis-Cummings Interaction

**Why Sp and Sm operators?**

The Jaynes-Cummings/Tavis-Cummings interaction couples spin flips to photon creation/annihilation:

```
H_TC = g Σᵢ (a σ⁺ᵢ + a† σ⁻ᵢ)
```

**NOT:**
```
H_wrong = g(a + a†) Σᵢ σˣᵢ   ← WRONG!
```

**Why the first is correct:**

σˣ = (σ⁺ + σ⁻)/2, so the "wrong" form includes counter-rotating terms:
```
g(a + a†)(σ⁺ + σ⁻) = g(aσ⁺ + a†σ⁻) + g(aσ⁻ + a†σ⁺)
                      \_____________/   \________________/
                       rotating-wave    counter-rotating
                       (conserves E)    (violates E)
```

**Rotating-wave approximation (RWA):**
- Drop counter-rotating terms (aσ⁻ + a†σ⁺)
- Valid when g << ω
- Conserves excitation number

**Result:** H_TC = g(aσ⁺ + a†σ⁻) ✓

### Ladder Operators

**Raising operator: σ⁺**
```
σ⁺|↓⟩ = |↑⟩
σ⁺|↑⟩ = 0
```

**Lowering operator: σ⁻**
```
σ⁻|↑⟩ = |↓⟩
σ⁻|↓⟩ = 0
```

**Relation to Pauli matrices:**
```
σˣ = σ⁺ + σ⁻
σʸ = -i(σ⁺ - σ⁻)
[σ⁺, σ⁻] = σᶻ
```

### Boson Operators

**Annihilation: a**
```
a|n⟩ = √n |n-1⟩
```

**Creation: a†**
```
a†|n⟩ = √(n+1) |n+1⟩
```

**Number: b†b**
```
b†b|n⟩ = n|n⟩
```

### Conservation Laws

**Total excitation number:**
```
N_exc = b†b + Σᵢ (σᶻᵢ + 1)/2
```

This is conserved by H_TC!
- a σ⁺: Decrease photons, increase spin-ups → N_exc same
- a† σ⁻: Increase photons, decrease spin-ups → N_exc same

**This enables block-diagonal structure in certain bases.**

---

## Channel Construction

### Overview

This model uses the **three-category channel structure**:

```json
"channels": {
  "spin_channels": [...],      // Auto-wrapped with boson identity
  "boson_channels": [...],     // Pure boson terms
  "spinboson_channels": [...]  // Explicit spin-boson coupling
}
```

### Spin Channels: Long-Range Ising

```json
"spin_channels": [
  {
    "type": "PowerLawCoupling",
    "op1": "Z",
    "op2": "Z",
    "strength": 1.0,
    "alpha": 1.5,
    "n_exp": 10,
    "N": 20
  },
  {
    "type": "Field",
    "op": "Z",
    "strength": 0.0
  }
]
```

**What this does:**
- Power-law Ising interaction between spins
- Parser auto-wraps with boson identity (Ib)
- Uses FSM decomposition: 1/r^α ≈ Σₖ νₖλₖʳ
- Bond dimension: O(K) = O(10) instead of O(N) = O(20)

**Physical term:** J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^1.5

### Boson Channels: Cavity Energy

```json
"boson_channels": [
  {
    "type": "BosonOnly",
    "op": "Bn",
    "strength": 1.0
  }
]
```

**What this does:**
- Acts only on boson site (spins have identity)
- Bn = b†b (number operator)
- Diagonal in Fock basis

**Physical term:** ω b†b

### SpinBoson Channels: Tavis-Cummings Coupling

```json
"spinboson_channels": [
  {
    "spin_channels": [
      {"type": "Field", "op": "Sp", "strength": 1.0}
    ],
    "boson_op": "a",
    "strength": 0.2
  },
  {
    "spin_channels": [
      {"type": "Field", "op": "Sm", "strength": 1.0}
    ],
    "boson_op": "adag",
    "strength": 0.2
  }
]
```

**What this does:**
- First channel: g a Σᵢ σ⁺ᵢ (absorption)
- Second channel: g a† Σᵢ σ⁻ᵢ (emission)
- Explicit spin-boson coupling

**Physical term:** g(a Σᵢ σ⁺ᵢ + a† Σᵢ σ⁻ᵢ)

**Physical processes:**
- Absorption: Photon destroyed (a) + Spin raised (σ⁺)
- Emission: Photon created (a†) + Spin lowered (σ⁻)

---

## Configuration

### Complete Config Structure

```json
{
  "model": {
    "name": "custom_spinboson",
    "params": {
      "N_spins": 20,
      "nmax": 5,
      "dtype": "Float64",
      "channels": {
        "spin_channels": [...],
        "boson_channels": [...],
        "spinboson_channels": [...]
      }
    }
  }
}
```

See `spinboson_tc_model_config.json` for the full configuration.

**System:**
- 1 boson site (truncated at 5 photons)
- 20 spin-1/2 sites
- Total Hilbert space: 6 × 2²⁰ ≈ 6 million states

**Physical Parameters:**
- J = 1.0 (Ising coupling)
- α = 1.5 (power-law exponent)
- g = 0.2 (Tavis-Cummings coupling)
- ω = 1.0 (boson frequency)
- n_exp = 10 (exponentials for FSM)

---

## Usage

### Run the Example

```bash
cd examples/models/custom/spinboson_longrange
julia build_and_analyze.jl
```

## Implementation Notes

### Site Ordering

```
Sites: [Boson, Spin_1, Spin_2, ..., Spin_N]
Index:    1      2       3           N+1
```

**Important:**
- Boson site is ALWAYS first
- Spin sites follow
- MPO tensors respect this ordering

### Channel Categories

**spin_channels:**
- Pure spin interactions (Ising, Heisenberg, fields)
- Parser auto-wraps with boson identity
- User doesn't need to know about Ib

**boson_channels:**
- Pure boson terms (energy, nonlinearity)
- BosonOnly type
- Spins have identity operator

**spinboson_channels:**
- Explicit spin-boson coupling
- Contains nested spin_channels
- Specifies boson_op and coupling strength

### Operators

**Boson operators:**
- `a` - Annihilation
- `adag` - Creation
- `Bn` - Number (b†b)
- `Ib` - Identity

**Spin operators:**
- `X, Y, Z` - Pauli matrices
- `Sp` - Raising (σ⁺)
- `Sm` - Lowering (σ⁻)
- `I` - Identity

### FSM with Spin-Boson

**Key insight:** FSM decomposition works on spin sites only
- Boson site not involved in power-law
- PowerLawCoupling creates FSM for spins
- Boson has identity (auto-wrapped)
- Total MPO combines both

**Result:**
- Bond dimension manageable
- Long-range interactions efficient
- Heterogeneous sites no problem

## Summary

**This example demonstrates:**

✅ **Heterogeneous sites** - Boson + spins in one system  
✅ **Long-range interactions** - FSM works for spin-boson!  
✅ **Correct Tavis-Cummings** - Sp/Sm operators, excitation conservation  
✅ **Clean channel structure** - spin/boson/spinboson categories  
✅ **Physical relevance** - Cavity QED, trapped ions, circuit QED  
✅ **Advanced physics** - Dicke superradiance, long-range order

**Key technical achievement:**
- FSM decomposition extends to heterogeneous systems
- Bond dimension stays manageable (χ~14 vs χ~N)
- Complete control via custom channels
- Clean separation: user writes physics, parser handles implementation

**Physical systems modeled:**
- Trapped ion arrays
- Cavity QED setups
- Circuit QED devices
- Dipolar gases in cavities

**This is cutting-edge computational quantum optics!**
