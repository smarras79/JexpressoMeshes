"""
Basic usage examples for JexpressoMeshGenerator

This script demonstrates how to generate common mesh types used in Jexpresso simulations.
"""

# Add the src directory to the load path
push!(LOAD_PATH, "../src")

using JexpressoMeshGenerator

println("=" ^ 80)
println("JexpressoMeshGenerator - Basic Usage Examples")
println("=" ^ 80)

# Ensure output directory exists
output_dir = "output_meshes"
if !isdir(output_dir)
    mkdir(output_dir)
end

#-------------------------------------------------------------------------------
# Example 1: Simple 2D mesh (similar to hexa_TFI_2x2.geo)
#-------------------------------------------------------------------------------
println("\n[Example 1] Generating 2D structured mesh (2x1 elements)...")

params_2d = MeshParams2D(
    2,      # nx: 2 elements in x
    1,      # ny: 1 element in y
    -1.0,   # xmin
    1.0,    # xmax
    0.0,    # ymin
    1.0     # ymax
)

generate_2d_structured_mesh(params_2d, output_file="$output_dir/mesh_2x1.msh")

#-------------------------------------------------------------------------------
# Example 2: 2D mesh with boundary condition tags
#-------------------------------------------------------------------------------
println("\n[Example 2] Generating 2D mesh with custom boundary tags...")

# Create 10x10 unit square mesh with boundary conditions
params_2d_bc = MeshParams2D(
    10,     # nx
    10,     # ny
    0.0,    # xmin
    1.0,    # xmax
    0.0,    # ymin
    1.0,    # ymax
    boundary_tags = Dict(
        "domain" => [1],
        # Note: Boundary tagging is simplified in this version
        # Lines are: 1=bottom, 2=right, 3=top, 4=left
    )
)

generate_2d_structured_mesh(params_2d_bc, output_file="$output_dir/mesh_10x10_unit_square.msh")

#-------------------------------------------------------------------------------
# Example 3: 3D mesh (similar to hexa_TFI_10x10x10.geo)
#-------------------------------------------------------------------------------
println("\n[Example 3] Generating 3D structured mesh (10x1x10 elements)...")

params_3d = MeshParams3D(
    10,      # nx
    1,       # ny
    10,      # nz
    -5000.0, # xmin
    5000.0,  # xmax
    -3000.0, # ymin
    1500.0,  # ymax
    0.0,     # zmin
    10000.0  # zmax
)

generate_3d_structured_mesh(params_3d, output_file="$output_dir/mesh_10x1x10.msh")

#-------------------------------------------------------------------------------
# Example 4: 2D periodic mesh
#-------------------------------------------------------------------------------
println("\n[Example 4] Generating 2D periodic mesh (20x20 elements)...")

params_periodic_2d = MeshParams2D(
    20,    # nx
    20,    # ny
    0.0,   # xmin
    10.0,  # xmax
    0.0,   # ymin
    10.0   # ymax
)

generate_2d_periodic_mesh(
    params_periodic_2d,
    periodic_x = true,
    periodic_y = true,
    output_file = "$output_dir/mesh_20x20_periodic.msh"
)

#-------------------------------------------------------------------------------
# Example 5: 3D periodic mesh (similar to LESICP.geo)
#-------------------------------------------------------------------------------
println("\n[Example 5] Generating 3D periodic LESICP-style mesh (32x32x16 elements)...")

params_lesicp = MeshParams3D(
    32,      # nx
    32,      # ny
    16,      # nz
    0.0,     # xmin
    10240.0, # xmax (10.24 km)
    0.0,     # ymin
    10240.0, # ymax (10.24 km)
    0.0,     # zmin
    3500.0   # zmax (3.5 km)
)

generate_3d_periodic_mesh(
    params_lesicp,
    periodic_x = true,
    periodic_y = true,
    periodic_z = false,
    output_file = "$output_dir/LESICP_32x32x16.msh"
)

#-------------------------------------------------------------------------------
# Example 6: 3D mesh with vertical stretching
#-------------------------------------------------------------------------------
println("\n[Example 6] Generating 3D stretched mesh (32x16x16 elements)...")

params_stretched = MeshParams3D(
    32,      # nx
    16,      # ny
    16,      # nz
    0.0,     # xmin
    10000.0, # xmax
    0.0,     # ymin
    5000.0,  # ymax
    0.0,     # zmin
    3000.0   # zmax
)

# Stretching factor > 1.0 refines mesh near bottom (z=0)
create_stretched_mesh_3d(
    params_stretched,
    1.05,  # 5% stretching factor
    output_file = "$output_dir/mesh_32x16x16_stretched.msh"
)

#-------------------------------------------------------------------------------
# Example 7: Large LESICP mesh (similar to actual benchmarks)
#-------------------------------------------------------------------------------
println("\n[Example 7] Generating large LESICP mesh (64x64x36 elements)...")
println("Note: This may take a moment to generate...")

params_lesicp_large = MeshParams3D(
    64,      # nx
    64,      # ny
    36,      # nz
    0.0,     # xmin
    10240.0, # xmax
    0.0,     # ymin
    10240.0, # ymax
    0.0,     # zmin
    3500.0   # zmax
)

generate_3d_periodic_mesh(
    params_lesicp_large,
    periodic_x = true,
    periodic_y = true,
    periodic_z = false,
    output_file = "$output_dir/LESICP_64x64x36_10kmX10kmX3dot5km.msh"
)

println("\n" * "=" ^ 80)
println("All meshes generated successfully!")
println("Output directory: $output_dir")
println("=" ^ 80)
println("\nYou can now use these .msh files directly in Jexpresso.")
