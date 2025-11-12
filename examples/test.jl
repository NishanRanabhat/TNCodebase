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

spin_site = SpinSite(1/2,T=ComplexF64) #define a spin 1/2 particle 

#build the system by putting the boson at site 0 and spins at rest of the sites
Ns = 16 #total spins
spinsystem = fill(spin_site,Ns)

"""
define a state
"""

labels = fill((:Z,2),Ns)
psi = product_state(spinsystem,labels)

#Ising part
JX = 1.0; #coupling strength
JY = 1.0
JZ = 0.5

#define Spin channels
spinchannel0 = [FiniteRangeCoupling(:X,:X,1,JX),FiniteRangeCoupling(:Y,:Y,1,JY),FiniteRangeCoupling(:Z,:Z,1,JZ)]

#Boson part
#g = 0.2; #spin boson interaction strength
#w = 1.0 #boson energy

#spin boson channel
#channel = [SpinBosonInteraction(spinchannel1,:Ib,1.0),SpinBosonInteraction(spinchannel2,:a,g),SpinBosonInteraction(spinchannel2,:adag,g),BosonOnly(:Bn,w)]

#build Finite State Machine based on the channels
fsm = build_FSM(spinchannel0)

#build mpo from the Finite State Machine
ham = build_mpo(fsm,N=Ns,d=2,T=ComplexF64) 

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