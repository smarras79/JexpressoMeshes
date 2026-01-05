"""
Example: Generating 3D meshes with unstructured XZ plane

This example demonstrates how to generate 3D meshes where the XZ plane
(base surface) has semi-structured/unstructured elements while maintaining
structured layers in the Y direction.

Use cases:
- Complex terrain following in atmospheric simulations
- Meshes requiring flexibility in horizontal plane
- Combining boundary layer resolution with unstructured interiors
"""

push!(LOAD_PATH, "../src")

using JexpressoMeshGenerator

println("=" ^ 80)
println("3D Unstructured XZ Plane Mesh Generation")
println("=" ^ 80)

# Create output directory
output_dir = "output_meshes"
if !isdir(output_dir)
    mkdir(output_dir)
end

#-------------------------------------------------------------------------------
# Example 1: Basic unstructured XZ mesh
#-------------------------------------------------------------------------------
println("\n[Example 1] Generating basic unstructured XZ mesh (20x20x20 elements)...")
println("Domain: [-5000, 5000] × [0, 10000] × [0, 10000]")
println()

params_basic = MeshParams3D(
    20,      # nx
    20,      # ny
    20,      # nz
    -5000.0, # xmin
    5000.0,  # xmax
    0.0,     # ymin
    10000.0, # ymax
    0.0,     # zmin
    10000.0  # zmax
)

generate_3d_unstructured_xz_mesh(params_basic,
                                 output_file="$output_dir/unstructured_xz_20x20x20.msh")

println()
println("Key Features:")
println("  • Base surface (XZ plane) has structured boundaries but flexible interior")
println("  • Y-direction extrusion creates structured layers (20 layers)")
println("  • Results in hexahedral elements via recombination")
println("  • Boundary lines use transfinite meshing: 21 nodes in X, 21 nodes in Z")

#-------------------------------------------------------------------------------
# Example 2: Atmospheric boundary layer with unstructured horizontal
#-------------------------------------------------------------------------------
println("\n" * "-" ^ 80)
println("\n[Example 2] Atmospheric boundary layer mesh (unstructured XZ)...")
println("Domain: 10 km × 2 km × 3 km")
println()

params_abl = MeshParams3D(
    40,      # nx - horizontal resolution
    30,      # ny - vertical layers
    40,      # nz - horizontal resolution
    0.0,     # xmin
    10000.0, # xmax (10 km)
    0.0,     # ymin (surface)
    2000.0,  # ymax (2 km height)
    0.0,     # zmin
    10000.0  # zmax (10 km)
)

generate_3d_unstructured_xz_mesh(params_abl,
                                 output_file="$output_dir/abl_unstructured_xz_40x30x40.msh")

println()
println("Use case: Atmospheric boundary layer with terrain following capability")
println("  • Horizontal plane (XZ) can adapt to complex terrain")
println("  • Vertical direction maintains structured layers for BL resolution")

#-------------------------------------------------------------------------------
# Example 3: Coarse mesh for testing
#-------------------------------------------------------------------------------
println("\n" * "-" ^ 80)
println("\n[Example 3] Coarse test mesh (unstructured XZ)...")
println("Domain: [-1, 1] × [0, 1] × [0, 1]")
println()

params_coarse = MeshParams3D(
    5,      # nx
    5,      # ny
    5,      # nz
    -1.0,   # xmin
    1.0,    # xmax
    0.0,    # ymin
    1.0,    # ymax
    0.0,    # zmin
    1.0     # zmax
)

generate_3d_unstructured_xz_mesh(params_coarse,
                                 output_file="$output_dir/test_unstructured_xz_5x5x5.msh")

println()
println("Use case: Quick test mesh for algorithm development")

#-------------------------------------------------------------------------------
# Example 4: High-resolution horizontal plane
#-------------------------------------------------------------------------------
println("\n" * "-" ^ 80)
println("\n[Example 4] High-resolution horizontal mesh...")
println("Domain: 5 km × 1 km × 5 km")
println()

params_hires = MeshParams3D(
    80,      # nx - high horizontal resolution
    20,      # ny - moderate vertical resolution
    80,      # nz - high horizontal resolution
    0.0,     # xmin
    5000.0,  # xmax (5 km)
    0.0,     # ymin
    1000.0,  # ymax (1 km)
    0.0,     # zmin
    5000.0   # zmax (5 km)
)

generate_3d_unstructured_xz_mesh(params_hires,
                                 output_file="$output_dir/hires_unstructured_xz_80x20x80.msh")

println()
println("Use case: High-resolution simulations with flexible meshing")
println("  • 81×81 nodes on horizontal boundaries")
println("  • 21 structured vertical layers")

#-------------------------------------------------------------------------------
# Comparison table
#-------------------------------------------------------------------------------
println("\n" * "=" ^ 80)
println("Mesh Generation Complete!")
println("=" ^ 80)
println()
println("Comparison: Structured vs Unstructured XZ:")
println()
println("┌─────────────────────────┬─────────────────────┬──────────────────────┐")
println("│ Feature                 │ Fully Structured    │ Unstructured XZ      │")
println("├─────────────────────────┼─────────────────────┼──────────────────────┤")
println("│ Base surface (XZ)       │ Transfinite surface │ Free triangulation   │")
println("│ Boundary lines          │ Transfinite         │ Transfinite          │")
println("│ Y-direction extrusion   │ Structured layers   │ Structured layers    │")
println("│ Element type            │ Hexahedral          │ Hex (recombined)     │")
println("│ Flexibility             │ Low                 │ High (XZ plane)      │")
println("│ Ideal for              │ Regular domains     │ Complex geometries   │")
println("└─────────────────────────┴─────────────────────┴──────────────────────┘")
println()
println("Use:")
println("  • generate_3d_structured_mesh()     - Fully structured (fastest)")
println("  • generate_3d_unstructured_xz_mesh() - Semi-structured (flexible)")
println()
println("All meshes saved to: $output_dir")
println("=" ^ 80)
