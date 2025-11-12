# ============================================================================
# PART 1: Solver Builders
# ============================================================================

function build_solver_from_config(solver_config)
    solver_type = solver_config["type"]
    
    if solver_type == "lanczos"
        krylov_dim = solver_config["krylov_dim"]
        max_iter = solver_config["max_iter"]
        return LanczosSolver(krylov_dim, max_iter)
        
    elseif solver_type == "krylov_exponential"
        krylov_dim = solver_config["krylov_dim"]
        tol = get(solver_config, "tol", 1e-8)
        return KrylovExponential(krylov_dim, tol)
        
    else
        error("Unknown solver type: $solver_type. Use 'lanczos' or 'krylov_exponential'")
    end
end

# ============================================================================
# PART 2: Options Builders
# ============================================================================

function build_options_from_config(options_config, algorithm_type)
    if algorithm_type == "dmrg"
        chi_max = options_config["chi_max"]
        cutoff = options_config["cutoff"]
        local_dim = options_config["local_dim"]
        return DMRGOptions(chi_max, cutoff, local_dim)
        
    elseif algorithm_type == "tdvp"
        dt = options_config["dt"]
        chi_max = options_config["chi_max"]
        cutoff = options_config["cutoff"]
        local_dim = options_config["local_dim"]
        return TDVPOptions(dt, chi_max, cutoff, local_dim)
        
    else
        error("Unknown algorithm type: $algorithm_type. Use 'dmrg' or 'tdvp'")
    end
end

# ============================================================================
# PART 3: Main Simulation Runner
# ============================================================================

"""
    run_simulation_from_config(config)

Main entry point: takes unified config, returns final state.

Builds:
1. Sites from system config
2. MPO from model config
3. MPS from state config
4. Runs algorithm with specified solver and options
"""

function run_simulation_from_config(config; base_dir="data")
    println("="^70)
    println("Starting Simulation from Config")
    println("="^70)
    
    # ════════════════════════════════════════════════════════════════════════
    # DATABASE SETUP (NEW!)
    # ════════════════════════════════════════════════════════════════════════
    
    println("\n[0/5] Setting up database...")
    
    # Check if already run
    #if config_already_run(config, base_dir)
    #    println("⚠️  WARNING: This config was already run!")
        
    #    runs = find_runs_by_config(config, base_dir)
    #    println("\nExisting runs:")
    #    for run in runs
    #        println("  - $(run["run_id"]) at $(run["timestamp"])")
    #    end
        
    #    print("\nContinue anyway? [y/N]: ")
    #    response = readline()
    #    if lowercase(strip(response)) != "y"
    #        println("Aborted by user")
    #        return nothing
    #    end
    #end
    
    # Setup run directory and initialize database
    run_id, run_dir = setup_run_directory(config, base_dir=base_dir)
    println("  ✓ Run ID: $run_id")
    println("  ✓ Data directory: $run_dir")
    
    # ────────────────────────────────────────────────────────────────────────
    # Build System Components (unchanged)
    # ────────────────────────────────────────────────────────────────────────
    
    println("\n[1/5] Building system components...")
        
    # Build Hamiltonian (MPO)
    ham = build_mpo_from_config(config)
    println("  ✓ Hamiltonian: $(length(ham.tensors)) site MPO")
    
    # Build initial state (MPS)
    psi = build_mps_from_config(config)
    println("  ✓ Initial state: $(length(psi.tensors)) site MPS")
    
    # Create MPSState
    state = MPSState(psi, ham; center=1)
    println("  ✓ MPSState created")
    
    # ────────────────────────────────────────────────────────────────────────
    # Parse Algorithm Configuration (unchanged)
    # ────────────────────────────────────────────────────────────────────────
    
    println("\n[2/5] Parsing algorithm configuration...")
    
    alg_config = config["algorithm"]
    algorithm_type = alg_config["type"]
    println("  Algorithm: $(algorithm_type)")
    
    # Build solver
    solver = build_solver_from_config(alg_config["solver"])
    println("  ✓ Solver: $(typeof(solver))")
    
    # Build options
    options = build_options_from_config(alg_config["options"], algorithm_type)
    println("  ✓ Options: $(typeof(options))")
    
    # Get run parameters
    n_sweeps = alg_config["run"]["n_sweeps"]
    println("  Sweeps: $n_sweeps")
    
    # ────────────────────────────────────────────────────────────────────────
    # Run Simulation (MODIFIED - now saves data!)
    # ────────────────────────────────────────────────────────────────────────
    
    println("\n[3/5] Running simulation...")
    println("="^70)
    
    try
        if algorithm_type == "dmrg"
            run_dmrg_simulation(state, solver, options, n_sweeps, run_dir)
            
        elseif algorithm_type == "tdvp"
            run_tdvp_simulation(state, solver, options, n_sweeps, run_dir)
            
        else
            error("Unknown algorithm: $algorithm_type")
        end
        
        # ────────────────────────────────────────────────────────────────────
        # Finalize Database (NEW!)
        # ────────────────────────────────────────────────────────────────────
        
        println("="^70)
        println("[4/5] Finalizing database...")
        finalize_run(run_dir, status="completed")
        println("  ✓ Run marked as completed")
        
    catch e
        # If simulation fails, mark as failed
        println("\n❌ Simulation failed!")
        finalize_run(run_dir, status="failed")
        rethrow(e)
    end
    
    # ────────────────────────────────────────────────────────────────────────
    # Finish
    # ────────────────────────────────────────────────────────────────────────
    
    println("\n[5/5] Simulation complete!")
    println("  Data saved in: $run_dir")
    println("="^70)
    
    return state, run_id, run_dir
end

# ============================================================================
# PART 4: Algorithm-Specific Runners
# ============================================================================

function run_dmrg_simulation(state, solver, options, n_sweeps, run_dir)
    energies = Float64[]
    
    for sweep in 1:n_sweeps
        # ────────────────────────────────────────────────────────────────────
        # Run DMRG sweep
        # ────────────────────────────────────────────────────────────────────
        
        # Right sweep
        energy_right = dmrg_sweep(state, solver, options, :right)
        # Left sweep
        energy_left = dmrg_sweep(state, solver, options, :left)
        push!(energies, energy_left)
        # ────────────────────────────────────────────────────────────────────
        # Compute observables
        # ────────────────────────────────────────────────────────────────────
        # Get bond dimensions
        bond_dims = [size(tensor, 1) for tensor in state.mps.tensors]
        max_bond_dim = maximum(bond_dims)
        
        # ────────────────────────────────────────────────────────────────────
        # Save data (NEW!)
        # ────────────────────────────────────────────────────────────────────
        
        extra_data = Dict(
            "energy" => energy_left,
            "max_bond_dim" => max_bond_dim,
        )
        
        save_mps_sweep(state, run_dir, sweep; extra_data=extra_data)
        
        # ────────────────────────────────────────────────────────────────────
        # Print progress
        # ────────────────────────────────────────────────────────────────────
        
        if sweep % 1 == 0
            println("Sweep $sweep: E = $energy_left, χ_max = $max_bond_dim")
        end
    end
    
    println("\nFinal Energy: $(energies[end])")
end

function run_tdvp_simulation(state, solver, options, n_sweeps, run_dir)
    # Current time
    current_time = 0.0
    
    for sweep in 1:n_sweeps
        # ────────────────────────────────────────────────────────────────────
        # Run TDVP sweep
        # ────────────────────────────────────────────────────────────────────
        
        # Right sweep
        tdvp_sweep(state, solver, options, :right)
        
        # Left sweep
        tdvp_sweep(state, solver, options, :left)
        
        # Update time (one full sweep = one time step)
        current_time += options.dt
        
        # ────────────────────────────────────────────────────────────────────
        # Compute observables
        # ────────────────────────────────────────────────────────────────────
        
        # Get bond dimensions
        bond_dims = [size(tensor, 1) for tensor in state.mps.tensors]
        max_bond_dim = maximum(bond_dims)
        
        # Optionally compute energy (can be expensive)
        # energy = compute_expectation(state.mps, state.mpo)
        
        #IMPORTANT: CALCULATE THE LIST OF SINGULAR VALUES HERE AND ADD IN EXTRA DATA

        # ────────────────────────────────────────────────────────────────────
        # Save data (NEW!)
        # ────────────────────────────────────────────────────────────────────
        
        extra_data = Dict(
            "time" => current_time,           # Critical for TDVP!
            "max_bond_dim" => max_bond_dim,
            #"bond_dims" => bond_dims
            # "energy" => energy  # Uncomment if you compute it
        )
        
        save_mps_sweep(state, run_dir, sweep; extra_data=extra_data)
        
        # ────────────────────────────────────────────────────────────────────
        # Print progress
        # ────────────────────────────────────────────────────────────────────
        
        if sweep % 10 == 0  # Print every 10 sweeps for TDVP
            println("Sweep $sweep: t = $current_time, χ_max = $max_bond_dim")
        end
    end
    
    println("\nTDVP simulation complete")
    println("Final time: $current_time")
end