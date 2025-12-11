# Installation Guide

## Quick Setup (5 minutes)

### 1. Clone the Repository

```bash
git clone https://github.com/NishanRanabhat/TNCodebase.git
cd TNCodebase
```

### 2. Install Julia

Download Julia 1.9 or later from [julialang.org](https://julialang.org/downloads/)

### 3. Install Dependencies

Open Julia REPL in the TNCodebase directory:

```bash
julia
```

Then activate and instantiate the project:

```julia
using Pkg
Pkg.activate(".")
Pkg.instantiate()
```

This will automatically install all required packages:
- TensorOperations.jl
- JSON.jl
- JLD2.jl
- SHA (standard library)
- LinearAlgebra (standard library)
- Dates (standard library)
- Printf (standard library)

### 4. Test Installation

```julia
Pkg.test()
```

You should see: `✓ All basic tests passed!`

### 5. Load the Package

```julia
using TNCodebase

# You're ready to go!
```

---

### Alternative: One-Command Setup

Alternatively, you can run the setup script from your terminal instead of using the Julia REPL:

```bash
bash setup.sh
```

This script performs all the steps above (activate, instantiate, and test) automatically.

For HPC clusters with SLURM, submit it as a job instead:

```bash
sbatch setup.sh
```
---

## For full worked out examples explore

 Explore the [Examples](examples/)

---

## Directory Structure After Setup

```
TNCodebase/
├── Project.toml         # ✓ Dependencies
├── Manifest.toml        # ✓ Created after Pkg.instantiate()
├── setup.sh             # ✓ Setup script
├── src/
│   └── TNCodebase.jl    # Main module
├── examples/            # Working examples
├── test/
│   └── runtests.jl      # Test suite
└── data/                # Created automatically when running simulations
```

---

## Troubleshooting

### Issue: "ERROR: LoadError: ArgumentError: Package TNCodebase not found"
**Solution**: You need to activate the environment first:
```julia
using Pkg
Pkg.activate(".")
using TNCodebase  # Now it works
```

### Issue: Dependencies not installing
**Solution**: Update Julia registry and try again:
```julia
Pkg.update()
Pkg.instantiate()
```

---

## For Development

If you want to modify the code and have changes reflected immediately:

```julia
using Pkg
Pkg.activate(".")
Pkg.develop(path=".")  # Tells Julia to use local version

using Revise  # Install with: Pkg.add("Revise")
using TNCodebase

# Now changes to source files are reflected immediately!
```


## System Requirements

- **Julia**: 1.9 or later
- **RAM**: Minimum 4GB (16GB+ recommended for large systems)
- **Disk**: ~500MB for package + dependencies
- **OS**: Linux, macOS, or Windows (Linux recommended for best performance)

## Performance Tips

1. **Use multiple threads**: Start Julia with threads
   ```bash
   julia --threads=auto
   ```

2. **Precompile for faster loading**:
   ```julia
   using Pkg
   Pkg.activate(".")
   Pkg.precompile()
   ```

3. **For large simulations**: Use a machine with sufficient RAM
   - N=100, χ=200: ~8GB RAM
   - N=500, χ=1000: ~64GB RAM
