# Add src to LOAD_PATH and load the module
using Revise
using Test
using MKL
using LinearAlgebra
using BenchmarkTools
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
boson_site = BosonSite(nmax,T=ComplexF64) #define a Boson with nmax=4 

#build the system by putting the boson at site 0 and spins at rest of the sites
Ns = 16 #total spins
spinboson = vcat(boson_site,fill(spin_site,Ns))

"""
define a state
"""

labels = vcat(2,fill((:X,1),Ns))
psi = product_state(spinboson,labels)

"""
build Hamiltonian as MPO
"""

#Ising part
J = -1.0; #coupling strength
alpha = 1.5; #range of interaction
n = 7; #number of exponential to approximate the 1/r^a interaction
h = -1.0;

#define Spin channels
spinchannel1 = [PowerLawCoupling(:X,:X,J,alpha,n,Ns),Field(:X,h)]
spinchannel2 = [Field(:Z,1.0)]

#Boson part
g = 0.2; #spin boson interaction strength
w = 1.0 #boson energy

#spin boson channel
channel = [SpinBosonInteraction(spinchannel1,:Ib,1.0),SpinBosonInteraction(spinchannel2,:a,g),SpinBosonInteraction(spinchannel2,:adag,g),BosonOnly(:Bn,w)]

#build Finite State Machine based on the channels
fsm = build_FSM(channel)

#build mpo from the Finite State Machine
ham = build_mpo(fsm,N=Ns+1,d=2,nmax=nmax) 

#build state
state = MPSState(psi,ham; center=1)

#build solver
krylov_dim = 14 
tol = 0.00000001
solver = KrylovExponential(krylov_dim,tol)

#define TDVP options
dt = 0.01
chi_max = 100
cutoff = 0.00000001
local_dim = 2
options = TDVPOptions(dt,chi_max,cutoff,local_dim)

for i in 1:200
    @time tdvp_sweep(state,solver,options,:right)
    @time tdvp_sweep(state,solver,options,:left)
end
