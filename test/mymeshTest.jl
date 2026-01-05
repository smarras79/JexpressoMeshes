using Pkg
Pkg.add("Gmsh")

push!(LOAD_PATH, "../src")
using JexpressoMeshGenerator

# Create a 10x10 mesh on a unit square
params = MeshParams2D(10, 10, -5000, 5000.0, 0.0, 10000.0)
generate_2d_structured_mesh(params, output_file="../meshes/gmsh_grids/test_mesh_10x10.msh")
