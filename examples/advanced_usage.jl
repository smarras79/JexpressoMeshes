"""
Advanced usage examples for JexpressoMeshGenerator

This script demonstrates advanced mesh generation techniques including:
- Custom boundary condition configurations
- Multi-block meshes
- Meshes for specific atmospheric and fluid dynamics applications
"""

push!(LOAD_PATH, "../src")

using JexpressoMeshGenerator

println("=" ^ 80)
println("JexpressoMeshGenerator - Advanced Usage Examples")
println("=" ^ 80)

# Ensure output directory exists
output_dir = "output_meshes"
if !isdir(output_dir)
    mkdir(output_dir)
end

#-------------------------------------------------------------------------------
# Example 1: BOMEX case mesh (Barbados Oceanographic and Meteorological Experiment)
#-------------------------------------------------------------------------------
println("\n[Example 1] Generating BOMEX case mesh (16x16x19 elements)...")

params_bomex = MeshParams3D(
    16,     # nx
    16,     # ny
    19,     # nz
    0.0,    # xmin
    6400.0, # xmax (6.4 km)
    0.0,    # ymin
    6400.0, # ymax (6.4 km)
    0.0,    # zmin
    3000.0  # zmax (3 km)
)

generate_3d_periodic_mesh(
    params_bomex,
    periodic_x = true,
    periodic_y = true,
    periodic_z = false,
    output_file = "$output_dir/hexa_BOMEX_16x16x19.msh"
)

#-------------------------------------------------------------------------------
# Example 2: Rayleigh-Bénard convection mesh
#-------------------------------------------------------------------------------
println("\n[Example 2] Generating Rayleigh-Bénard convection mesh (40x40 elements)...")

params_rb = MeshParams2D(
    40,    # nx
    40,    # ny
    0.0,   # xmin
    1.0,   # xmax
    0.0,   # ymin
    1.0    # ymax
)

generate_2d_periodic_mesh(
    params_rb,
    periodic_x = true,
    periodic_y = false,  # Top and bottom are walls
    output_file = "$output_dir/Rayleigh_Benard_40x40_periodic.msh"
)

#-------------------------------------------------------------------------------
# Example 3: Channel flow / Turbulent channel flow mesh
#-------------------------------------------------------------------------------
println("\n[Example 3] Generating channel flow mesh with wall-resolved LES...")

params_channel = MeshParams3D(
    120,    # nx - streamwise direction
    31,     # ny - wall-normal direction (stretched)
    1,      # nz - spanwise direction (can be increased for 3D)
    0.0,    # xmin
    4.0,    # xmax (4π or similar periodic length)
    0.0,    # ymin
    2.0,    # ymax (channel height)
    0.0,    # zmin
    2.0     # zmax
)

# Use stretching in y-direction for wall-resolved simulations
create_stretched_mesh_3d(
    params_channel,
    1.08,  # Strong stretching near walls
    output_file = "$output_dir/channel_flow_120x31x1_stretched.msh"
)

#-------------------------------------------------------------------------------
# Example 4: Squall line simulation mesh (2D atmospheric dynamics)
#-------------------------------------------------------------------------------
println("\n[Example 4] Generating 2D squall line mesh...")

params_squall = MeshParams2D(
    200,     # nx - horizontal extent
    50,      # ny - vertical extent
    0.0,     # xmin
    100000.0,# xmax (100 km)
    0.0,     # ymin
    20000.0  # ymax (20 km height)
)

generate_2d_periodic_mesh(
    params_squall,
    periodic_x = true,
    periodic_y = false,
    output_file = "$output_dir/squall_line_2d_200x50.msh"
)

#-------------------------------------------------------------------------------
# Example 5: LES with varying resolution - coarse to fine
#-------------------------------------------------------------------------------
println("\n[Example 5] Generating series of LES meshes with increasing resolution...")

# Coarse mesh
params_coarse = MeshParams3D(16, 16, 10, 0.0, 5000.0, 0.0, 5000.0, 0.0, 2000.0)
generate_3d_periodic_mesh(params_coarse, periodic_x=true, periodic_y=true,
                          output_file="$output_dir/LES_coarse_16x16x10.msh")

# Medium mesh
params_medium = MeshParams3D(32, 32, 20, 0.0, 5000.0, 0.0, 5000.0, 0.0, 2000.0)
generate_3d_periodic_mesh(params_medium, periodic_x=true, periodic_y=true,
                          output_file="$output_dir/LES_medium_32x32x20.msh")

# Fine mesh
params_fine = MeshParams3D(64, 64, 40, 0.0, 5000.0, 0.0, 5000.0, 0.0, 2000.0)
generate_3d_periodic_mesh(params_fine, periodic_x=true, periodic_y=true,
                          output_file="$output_dir/LES_fine_64x64x40.msh")

#-------------------------------------------------------------------------------
# Example 6: Stratified atmosphere mesh with strong vertical stretching
#-------------------------------------------------------------------------------
println("\n[Example 6] Generating stratified atmosphere mesh...")

params_strat = MeshParams3D(
    80,      # nx
    40,      # ny
    45,      # nz - many levels for vertical resolution
    0.0,     # xmin
    10000.0, # xmax (10 km)
    0.0,     # ymin
    5000.0,  # ymax (5 km)
    0.0,     # zmin
    2800.0   # zmax (2.8 km height)
)

# Strong stretching for atmospheric boundary layer resolution
create_stretched_mesh_3d(
    params_strat,
    1.10,  # 10% stretching - very strong for ABL
    output_file = "$output_dir/stratified_atmos_80x40x45_stretched.msh"
)

#-------------------------------------------------------------------------------
# Example 7: Test/benchmark meshes for scaling studies
#-------------------------------------------------------------------------------
println("\n[Example 7] Generating benchmark meshes for scaling studies...")

# Small test mesh
params_test = MeshParams3D(2, 2, 2, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
generate_3d_structured_mesh(params_test, output_file="$output_dir/test_2x2x2.msh")

# Scaling test mesh (cubic domain for weak scaling)
params_scaling = MeshParams3D(32, 32, 32, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
generate_3d_periodic_mesh(params_scaling, periodic_x=true, periodic_y=true, periodic_z=true,
                          output_file="$output_dir/scaling_32x32x32_periodic.msh")

#-------------------------------------------------------------------------------
# Example 8: DYCOMS-II case (stratocumulus)
#-------------------------------------------------------------------------------
println("\n[Example 8] Generating DYCOMS-II stratocumulus case mesh...")

params_dycoms = MeshParams3D(
    48,      # nx
    48,      # ny
    100,     # nz - high vertical resolution for cloud layer
    0.0,     # xmin
    6400.0,  # xmax (6.4 km)
    0.0,     # ymin
    6400.0,  # ymax (6.4 km)
    0.0,     # zmin
    1500.0   # zmax (1.5 km)
)

generate_3d_periodic_mesh(
    params_dycoms,
    periodic_x = true,
    periodic_y = true,
    periodic_z = false,
    output_file = "$output_dir/dycoms_48x48x100.msh"
)

println("\n" * "=" ^ 80)
println("All advanced meshes generated successfully!")
println("Output directory: $output_dir")
println("=" ^ 80)
println("\nThese meshes are ready for use in Jexpresso atmospheric and fluid dynamics simulations.")
