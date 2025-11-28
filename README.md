# TNCodebase: Tensor Network Framework for Quantum Many-Body Dynamics

A comprehensive, production-ready Julia package for simulating quantum many-body systems using tensor network methods. Implements state-of-the-art algorithms including DMRG (Density Matrix Renormalization Group) and TDVP (Time-Dependent Variational Principle) with an emphasis on extensibility, performance, and reproducibility.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Julia](https://img.shields.io/badge/Julia-1.9+-blue.svg)](https://julialang.org/)

---

## Overview

TNCodebase provides a complete framework for tensor network simulations with:
- **Flexible algorithm implementations**: DMRG for ground states, TDVP for time evolution
- **Config-driven workflow**: JSON-based specification of models, states, and algorithms
- **Automatic data management**: Hash-based indexing and storage for reproducible research
- **Extensible architecture**: Easy addition of new Hamiltonians, observables, and algorithms
- **Production-quality code**: Comprehensive testing, documentation, and benchmarks

The package is designed for both method development and large-scale numerical studies, with particular emphasis on long-range interactions and open quantum systems.

---

## Key Features

### 🔬 **Algorithms**
- **DMRG**: Two-site algorithm with Lanczos eigensolver for ground state search
- **TDVP**: Two-site + one-site algorithm with Krylov exponential integrator for time evolution
- **Optimized tensor operations**: Canonical form management, SVD truncation, environment caching

### 🎯 **Physical Systems**
- **Spin chains**: Arbitrary spin-S with custom operators
- **Long-range interactions**: Exponential and power-law couplings via finite state machines
- **Spin-boson models**: Coupled spin-boson systems for open quantum dynamics
- **Custom Hamiltonians**: Flexible channel-based construction

### 📊 **Observables**
- Single-site and two-site expectation values
- Correlation functions (connected and raw)
- Entanglement entropy and spectrum
- Energy expectation and variance

### 🗄️ **Data Management**
- Hash-based simulation indexing for O(1) lookup
- Automatic saving of MPS states and metadata
- Time-based queries for TDVP simulations
- Separate observable calculation and storage

---

## Quick Start

### Installation

```julia
# Clone the repository
git clone https://github.com/yourusername/TNCodebase.git
cd TNCodebase

# Add to Julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

### Basic Usage

```julia
using JSON
using TNCodebase

# 1. Define simulation via config file
config = JSON.parsefile("examples/01_ground_state_dmrg/config.json")

# 2. Run simulation (auto-saves results)
state, run_id, run_dir = run_simulation_from_config(config)

# 3. Load results
latest = get_latest_run_for_config(config, base_dir="data")
mps, extra_data = load_mps_sweep(latest["run_dir"], 50)

# 4. Calculate observables
obs_config = JSON.parsefile("examples/observables/magnetization.json")
obs_run_id, obs_run_dir = run_observable_calculation_from_config(obs_config)
results = load_all_observable_results(obs_run_dir)
```

---

## Example: Ground State Energy Convergence

```julia
using JSON, Plots
using TNCodebase

# DMRG simulation config
config = Dict(
    "system" => Dict("type" => "spin", "N" => 50),
    "model" => Dict(
        "name" => "transverse_field_ising",
        "params" => Dict("N" => 50, "J" => -1.0, "h" => 0.5,
                        "coupling_dir" => "Z", "field_dir" => "X")
    ),
    "state" => Dict("type" => "random", "params" => Dict("bond_dim" => 10)),
    "algorithm" => Dict(
        "type" => "dmrg",
        "solver" => Dict("type" => "lanczos", "krylov_dim" => 6, "max_iter" => 20),
        "options" => Dict("chi_max" => 100, "cutoff" => 1e-10, "local_dim" => 2),
        "run" => Dict("n_sweeps" => 50)
    )
)

# Run simulation
state, run_id, run_dir = run_simulation_from_config(config, base_dir="data")

# Load and plot energy convergence
metadata = JSON.parsefile(joinpath(run_dir, "metadata.json"))
energies = [sweep["energy"] for sweep in metadata["sweep_data"]]

plot(1:length(energies), energies,
     xlabel="Sweep", ylabel="Energy", 
     title="DMRG Ground State Convergence",
     legend=false, linewidth=2)
```

**Output**: Demonstrates exponential convergence to ground state energy.

---

## Example: Time Evolution with TDVP

```julia
# Start from polarized state
config = Dict(
    "system" => Dict("type" => "spin", "N" => 40),
    "model" => Dict(
        "name" => "transverse_field_ising",
        "params" => Dict("N" => 40, "J" => -1.0, "h" => 2.0,
                        "coupling_dir" => "Z", "field_dir" => "X")
    ),
    "state" => Dict(
        "type" => "prebuilt", "name" => "polarized",
        "params" => Dict("spin_direction" => "Z", "eigenstate" => 2)
    ),
    "algorithm" => Dict(
        "type" => "tdvp",
        "solver" => Dict("type" => "krylov_exponential", 
                        "krylov_dim" => 20, "tol" => 1e-10),
        "options" => Dict("dt" => 0.01, "chi_max" => 100, 
                         "cutoff" => 1e-10, "local_dim" => 2),
        "run" => Dict("n_sweeps" => 500)
    )
)

# Run time evolution
state, run_id, run_dir = run_simulation_from_config(config, base_dir="data")

# Calculate time-dependent magnetization
obs_config = Dict(
    "simulation" => Dict("config_file" => "config.json"),
    "observable" => Dict(
        "type" => "subsystem_expectation_sum",
        "params" => Dict("operator" => "Sz", "l" => 1, "m" => 40)
    ),
    "sweeps" => Dict("selection" => "all")
)

obs_run_id, obs_run_dir = run_observable_calculation_from_config(obs_config)
results = load_all_observable_results(obs_run_dir)

# Extract time and magnetization
times = [metadata["sweep_data"][i]["time"] for i in 1:length(results)]
magnetization = [results[i][2] for i in 1:length(results)]

plot(times, magnetization,
     xlabel="Time", ylabel="⟨Σᵢ Sᶻᵢ⟩",
     title="Quantum Quench Dynamics",
     legend=false, linewidth=2)
```

**Output**: Shows relaxation dynamics after sudden quench.

---

## Project Structure

```
TNCodebase/
├── src/
│   ├── Core/                   # Types, operators, finite state machines
│   ├── TensorOps/             # Canonicalization, SVD, environments
│   ├── Algorithms/            # DMRG, TDVP, solvers
│   ├── Builders/              # Config-driven construction
│   ├── Database/              # Data management system
│   ├── Runners/               # Simulation execution
│   └── Analysis/              # Observable calculations
│
├── examples/                   # Complete working examples
│   ├── 01_ground_state_dmrg/
│   ├── 02_time_evolution_tdvp/
│   ├── 03_entanglement_analysis/
│   ├── 04_long_range_interactions/
│   └── 05_spin_boson_model/
│
├── docs/                       # Documentation
│   ├── quickstart.md
│   ├── user_guide/
│   └── api_reference/
│
└── test/                       # Unit tests
```

---

## Configuration System

TNCodebase uses JSON configuration files to specify simulations, enabling:
- **Reproducibility**: Complete simulation specification in one file
- **Parameter sweeps**: Easy modification for systematic studies
- **Data organization**: Automatic indexing by configuration hash

### Config Structure

```json
{
  "system": {
    "type": "spin",
    "N": 50,
    "S": 0.5
  },
  "model": {
    "name": "transverse_field_ising",
    "params": {
      "J": -1.0,
      "h": 0.5,
      "coupling_dir": "Z",
      "field_dir": "X"
    }
  },
  "state": {
    "type": "prebuilt",
    "name": "neel"
  },
  "algorithm": {
    "type": "dmrg",
    "solver": { ... },
    "options": { ... },
    "run": { ... }
  }
}
```

See [`docs/config_reference.md`](docs/config_reference.md) for complete specification.

---

## Implemented Models

### Pre-built Models
- **Transverse Field Ising Model**: `H = J Σᵢ σᶻᵢσᶻᵢ₊₁ + h Σᵢ σˣᵢ`
- **Heisenberg Chain**: `H = Jₓ Σᵢ σˣᵢσˣᵢ₊₁ + Jᵧ Σᵢ σʸᵢσʸᵢ₊₁ + Jᵧ Σᵢ σᶻᵢσᶻᵢ₊₁`
- **Long-Range Ising**: `H = J Σᵢ<ⱼ σᶻᵢσᶻⱼ/|i-j|^α + h Σᵢ σˣᵢ`
- **Spin-Boson Model**: Coupled spin chain + bosonic mode

### Custom Models
Define models via channel specifications:
- Finite-range couplings
- Exponential decay couplings
- Power-law interactions (via sum-of-exponentials decomposition)
- Single-site fields

---

## Performance Highlights

- **Efficient tensor contractions**: Using TensorOperations.jl with optimal contraction ordering
- **Environment caching**: O(N) complexity per sweep for both DMRG and TDVP
- **Minimal memory allocation**: In-place operations where possible
- **Scalability**: Successfully tested on systems up to N=500 sites with χ=1000

**Benchmark** (N=100, χ=200, Intel Xeon):
- DMRG sweep: ~2.5 seconds
- TDVP sweep: ~3.5 seconds

---

## Advanced Features

### Long-Range Interactions via FSM
Implements power-law interactions using sum-of-exponentials decomposition, enabling efficient MPO construction:

```
1/r^α ≈ Σᵢ νᵢ λᵢ^r
```

Reduces bond dimension from O(N) to O(log N) while maintaining accuracy.

### Time-Based Queries for TDVP
```julia
# Load state at specific physical time
mps, extra_data, actual_time = load_mps_at_time(run_dir, time=1.5)
```

### Hash-Based Data Management
```julia
# Find all runs with same configuration
config = JSON.parsefile("config.json")
runs = find_runs_by_config(config, base_dir="data")

# Load specific run
mps, data = load_mps_sweep(runs[1]["run_dir"], sweep)
```

---

## Documentation

- **[Quickstart Guide](docs/quickstart.md)**: Get started in 30 minutes
- **[User Guide](docs/user_guide/)**: Comprehensive tutorials
- **[API Reference](docs/api_reference/)**: Function documentation
- **[Examples](examples/)**: Complete working examples with explanations

---

## Algorithm Details

### DMRG (Density Matrix Renormalization Group)
- Two-site algorithm for ground state search
- Lanczos eigensolver with Krylov subspace dimension control
- Adaptive bond dimension with SVD truncation
- Energy variance monitoring for convergence

### TDVP (Time-Dependent Variational Principle)
- Two-site + one-site algorithm for real/imaginary time evolution
- Krylov exponential integrator for matrix exponentials
- Local basis optimization at each time step
- Compatible with both unitary and non-unitary evolution

---

## Testing

```julia
using Pkg
Pkg.activate(".")
Pkg.test()
```

Test suite includes:
- Unit tests for tensor operations
- Algorithm convergence tests
- Observable calculation validation
- Configuration parsing tests

---

## Contributing

Contributions are welcome! Areas of particular interest:
- New algorithms (e.g., infinite DMRG, finite-temperature methods)
- Additional physical models
- Performance optimizations
- Documentation improvements

---

## Citation

If you use TNCodebase in your research, please cite:

```bibtex
@software{tncodbase2025,
  author = {Your Name},
  title = {TNCodebase: Tensor Network Framework for Quantum Many-Body Dynamics},
  year = {2025},
  url = {https://github.com/yourusername/TNCodebase}
}
```

---

## Related Methods

The algorithms implemented in TNCodebase are directly applicable to:
- **Quantum chemistry**: Multi-configurational electronic structure (DMRG-SCF, DMRG-CASPT2)
- **Nuclear structure**: Shell model calculations
- **Condensed matter**: Frustrated magnets, topological phases
- **Quantum information**: Entanglement dynamics, quantum circuits
- **AMO physics**: Cold atoms in optical lattices

The TDVP algorithm is mathematically equivalent to TD-DMRG and MCTDH in appropriate limits.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## Contact

**[Your Name]**  
PhD Candidate, [Your University]  
Email: your.email@university.edu  
GitHub: [@yourusername](https://github.com/yourusername)

---

## Acknowledgments

- Developed as part of PhD research on tensor network methods for quantum many-body systems
- Algorithms based on foundational work by White (1992), Haegeman et al. (2011), and others
- Built using Julia's ecosystem: TensorOperations.jl, JLD2.jl, JSON.jl

---

**Status**: Under active development | Contributions welcome | Documented and tested
