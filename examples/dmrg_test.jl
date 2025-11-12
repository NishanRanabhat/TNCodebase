# Add src to LOAD_PATH and load the module
using LinearAlgebra
using Revise
using Test
using MKL
BLAS.set_num_threads(6)

using TensorOperations

push!(LOAD_PATH, joinpath(@__DIR__, "..", "newsrc"))

# This both includes MyDMRG.jl and tells Revise to watch every file it pulls in
includet(joinpath(@__DIR__, "..", "newsrc", "TNCodebase.jl"))

using .TNCodebase

"""
Build the system a site at a time
"""

nmax = 32
spin_site = SpinSite(1/2,T=ComplexF64) #define a spin 1/2 particle 
boson_site = BosonSite(nmax,T=ComplexF64) #define a Boson awith nmax=nmax 

#build the system by putting the boson at site 0 and spins at rest of the sites
Ns = 16 #total spins
spinboson = vcat(boson_site,fill(spin_site,Ns))

"""
define a initial random state state
"""
psi = random_state(spinboson,5,T=Float64)

"""
build Hamiltonian as MPO
"""

#Ising part
J = -1.0; #coupling strength
alpha = 1.4; #range of interaction
n = min(Int(floor(Ns/2)-1.0),14); #number of exponential to approximate the 1/r^a interaction
h = -0.1;

#define Spin channels
spinchannel1 = [PowerLawCoupling(:Z,:Z,J,alpha,n,Ns),Field(:Z,h)]
spinchannel2 = [Field(:X,1.0)]

#Boson part
g = 2.4/sqrt(Ns); #spin boson interaction strength
w = 1.0 #boson energy

#spin boson channel
channel = [SpinBosonInteraction(spinchannel1,:Ib,1.0),SpinBosonInteraction(spinchannel2,:a,g),SpinBosonInteraction(spinchannel2,:adag,g),BosonOnly(:Bn,w)]

#build Finite State Machine based on the channels
fsm = build_FSM(channel)

#build mpo from the Finite State Machine
ham = build_mpo(fsm,N=Ns+1,d=2,nmax=nmax,T = Float64) 

#build state
state = MPSState(psi,ham; center=1)

#build solver
krylov_dim = 4 
max_iter = 14
solver = LanczosSolver(krylov_dim,max_iter)

#define DMRG options
chi_max = 256
cutoff = 0.00000001
local_dim = 2
options = DMRGOptions(chi_max,cutoff,local_dim)

for i in 1:50
    @time ener = dmrg_sweep(state,solver,options,:right)
    ener = dmrg_sweep(state,solver,options,:left)
    println(ener)
end
