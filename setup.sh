#!/bin/bash
#SBATCH --job-name=tncodebase_setup
#SBATCH --output=setup_%j.out
#SBATCH --error=setup_%j.err
#SBATCH --time=00:15:00
#SBATCH --mem=4G

julia --project=. -e '
    using Pkg
    Pkg.activate(".")
    Pkg.instantiate()
    Pkg.test()
'
