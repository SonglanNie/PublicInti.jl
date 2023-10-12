using Test
using Inti
using HMatrices
using Gmsh
using LinearAlgebra
using Random

Random.seed!(1)

include("test_utils.jl")

@testset "2D" begin
    # create a boundary and area meshes and quadrature only once
    Ω, msh = gmsh_disk(; center = [0.0, 0.0], rx = 1.0, ry = 1.0, meshsize = 0.05)
    Γ = Inti.external_boundary(Ω)
    Γ_quad = Inti.Quadrature(view(msh, Γ); qorder = 3)
    Ω_quad = Inti.Quadrature(view(msh, Ω); qorder = 3)
    # test various PDEs and integral operators
    for pde in (Inti.Laplace(; dim = 2), Inti.Helmholtz(; k = 1.2, dim = 2))
        @testset "PDE = $pde" begin
            for op in (Inti.single_layer_operator, Inti.double_layer_operator)
                iop = Inti.single_layer_operator(pde, Ω_quad)
                H = HMatrices.assemble_hmatrix(iop; atol = 1e-8)
                x = rand(eltype(iop), size(iop, 2))
                yapprox = H * x
                # test on a given index set
                idx_test = rand(1:size(iop, 1), 10)
                exact = iop[idx_test, :] * x
                @test yapprox[idx_test] ≈ exact atol = 1e-7
            end
        end
    end
end