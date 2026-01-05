"""
Basic tests for JexpressoMeshGenerator

Run with: julia test/runtests.jl
"""

push!(LOAD_PATH, "../src")

using Test
using JexpressoMeshGenerator

println("=" ^ 80)
println("Testing JexpressoMeshGenerator")
println("=" ^ 80)

# Create test output directory
test_output = "test_output"
if !isdir(test_output)
    mkdir(test_output)
end

@testset "JexpressoMeshGenerator Tests" begin

    @testset "MeshParams2D Construction" begin
        params = MeshParams2D(10, 10, 0.0, 1.0, 0.0, 1.0)
        @test params.nx == 10
        @test params.ny == 10
        @test params.xmin == 0.0
        @test params.xmax == 1.0
        @test params.ymin == 0.0
        @test params.ymax == 1.0
    end

    @testset "MeshParams3D Construction" begin
        params = MeshParams3D(10, 10, 10, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
        @test params.nx == 10
        @test params.ny == 10
        @test params.nz == 10
        @test params.xmin == 0.0
        @test params.xmax == 1.0
        @test params.ymin == 0.0
        @test params.ymax == 1.0
        @test params.zmin == 0.0
        @test params.zmax == 1.0
    end

    @testset "2D Structured Mesh Generation" begin
        params = MeshParams2D(2, 2, -1.0, 1.0, -1.0, 1.0)
        output_file = "$test_output/test_2x2.msh"

        # Should not throw error
        @test_nowarn generate_2d_structured_mesh(params, output_file=output_file)

        # Check file was created
        @test isfile(output_file)

        # Check file has content
        @test filesize(output_file) > 0

        println("  ✓ Generated 2D mesh: $output_file")
    end

    @testset "3D Structured Mesh Generation" begin
        params = MeshParams3D(2, 2, 2, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
        output_file = "$test_output/test_2x2x2.msh"

        @test_nowarn generate_3d_structured_mesh(params, output_file=output_file)
        @test isfile(output_file)
        @test filesize(output_file) > 0

        println("  ✓ Generated 3D mesh: $output_file")
    end

    @testset "2D Periodic Mesh Generation" begin
        params = MeshParams2D(4, 4, 0.0, 1.0, 0.0, 1.0)
        output_file = "$test_output/test_periodic_2d.msh"

        @test_nowarn generate_2d_periodic_mesh(params,
                                               periodic_x=true,
                                               periodic_y=true,
                                               output_file=output_file)
        @test isfile(output_file)
        @test filesize(output_file) > 0

        println("  ✓ Generated 2D periodic mesh: $output_file")
    end

    @testset "3D Periodic Mesh Generation" begin
        params = MeshParams3D(4, 4, 4, 0.0, 10.0, 0.0, 10.0, 0.0, 10.0)
        output_file = "$test_output/test_periodic_3d.msh"

        @test_nowarn generate_3d_periodic_mesh(params,
                                               periodic_x=true,
                                               periodic_y=true,
                                               periodic_z=false,
                                               output_file=output_file)
        @test isfile(output_file)
        @test filesize(output_file) > 0

        println("  ✓ Generated 3D periodic mesh: $output_file")
    end

    @testset "3D Stretched Mesh Generation" begin
        params = MeshParams3D(4, 4, 8, 0.0, 100.0, 0.0, 100.0, 0.0, 50.0)
        output_file = "$test_output/test_stretched.msh"
        stretch_factor = 1.05

        @test_nowarn create_stretched_mesh_3d(params, stretch_factor,
                                              output_file=output_file)
        @test isfile(output_file)
        @test filesize(output_file) > 0

        println("  ✓ Generated stretched mesh: $output_file")
    end

    @testset "LESICP-style Mesh" begin
        # Small version for testing
        params = MeshParams3D(8, 8, 8, 0.0, 1000.0, 0.0, 1000.0, 0.0, 500.0)
        output_file = "$test_output/test_LESICP_small.msh"

        @test_nowarn generate_3d_periodic_mesh(params,
                                               periodic_x=true,
                                               periodic_y=true,
                                               output_file=output_file)
        @test isfile(output_file)
        @test filesize(output_file) > 0

        println("  ✓ Generated LESICP-style mesh: $output_file")
    end

end

println("\n" * "=" ^ 80)
println("All tests passed! ✓")
println("Test meshes are in: $test_output/")
println("=" ^ 80)
