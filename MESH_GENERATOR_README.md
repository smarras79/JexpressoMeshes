# JexpressoMeshGenerator.jl

A standalone Julia module for generating structured meshes directly within Jexpresso using GMSH.jl. This eliminates the need for external GMSH scripting and provides a pure Julia interface for mesh generation.

## Overview

Previously, Jexpresso meshes were generated using external GMSH `.geo` scripts and the resulting `.msh` files were read into Jexpresso. This module allows users to generate meshes programmatically from within Julia, providing:

- **Direct integration**: Generate meshes without leaving the Julia environment
- **Programmatic control**: Create meshes with parameters, loops, and conditional logic
- **Type safety**: Leverage Julia's type system for mesh parameters
- **Reproducibility**: Version-controlled mesh generation scripts
- **Flexibility**: Easily create mesh families for sensitivity studies

## Installation

### Prerequisites

1. **Julia** (version 1.6 or later recommended)
2. **GMSH.jl** package

### Setup

1. Install GMSH.jl in your Julia environment:

```julia
using Pkg
Pkg.add("Gmsh")
```

2. Add the JexpressoMeshGenerator source to your Julia load path or include it directly:

```julia
# Option 1: Add to LOAD_PATH
push!(LOAD_PATH, "/path/to/JexpressoMeshes/src")
using JexpressoMeshGenerator

# Option 2: Include directly
include("/path/to/JexpressoMeshes/src/JexpressoMeshGenerator.jl")
using .JexpressoMeshGenerator
```

## Quick Start

### Simple 2D Mesh

```julia
using JexpressoMeshGenerator

# Create a 10x10 mesh on a unit square
params = MeshParams2D(10, 10, 0.0, 1.0, 0.0, 1.0)
generate_2d_structured_mesh(params, output_file="mesh_10x10.msh")
```

### Simple 3D Mesh

```julia
using JexpressoMeshGenerator

# Create a 20x20x20 mesh on a unit cube
params = MeshParams3D(20, 20, 20, 0.0, 1.0, 0.0, 1.0, 0.0, 1.0)
generate_3d_structured_mesh(params, output_file="mesh_20x20x20.msh")
```

### Periodic Mesh for LES

```julia
using JexpressoMeshGenerator

# LESICP-style mesh: 64x64x36 elements, periodic in x and y
params = MeshParams3D(64, 64, 36, 0.0, 10240.0, 0.0, 10240.0, 0.0, 3500.0)
generate_3d_periodic_mesh(params,
                          periodic_x=true,
                          periodic_y=true,
                          output_file="LESICP_64x64x36.msh")
```

## API Reference

### Data Types

#### `MeshParams2D`

Parameters for 2D structured meshes.

**Fields:**
- `nx::Int` - Number of elements in x-direction
- `ny::Int` - Number of elements in y-direction
- `xmin::Float64` - Minimum x-coordinate
- `xmax::Float64` - Maximum x-coordinate
- `ymin::Float64` - Minimum y-coordinate
- `ymax::Float64` - Maximum y-coordinate
- `boundary_tags::Dict{String,Vector{Int}}` - Physical boundary tags

#### `MeshParams3D`

Parameters for 3D structured meshes.

**Fields:**
- `nx::Int` - Number of elements in x-direction
- `ny::Int` - Number of elements in y-direction
- `nz::Int` - Number of elements in z-direction
- `xmin::Float64` - Minimum x-coordinate
- `xmax::Float64` - Maximum x-coordinate
- `ymin::Float64` - Minimum y-coordinate
- `ymax::Float64` - Maximum y-coordinate
- `zmin::Float64` - Minimum z-coordinate
- `zmax::Float64` - Maximum z-coordinate
- `boundary_tags::Dict{String,Vector{Int}}` - Physical boundary tags

### Functions

#### `generate_2d_structured_mesh`

```julia
generate_2d_structured_mesh(params::MeshParams2D;
                            recombine=true,
                            output_file=nothing)
```

Generate a 2D structured quadrilateral mesh using transfinite algorithm.

**Arguments:**
- `params` - Mesh parameters
- `recombine` - Recombine triangles into quads (default: true)
- `output_file` - Output filename (if provided, mesh is saved and GMSH finalized)

#### `generate_3d_structured_mesh`

```julia
generate_3d_structured_mesh(params::MeshParams3D;
                            recombine=true,
                            output_file=nothing)
```

Generate a 3D structured hexahedral mesh using transfinite algorithm with extrusion.

**Arguments:**
- `params` - Mesh parameters
- `recombine` - Recombine into hexahedra (default: true)
- `output_file` - Output filename

#### `generate_2d_periodic_mesh`

```julia
generate_2d_periodic_mesh(params::MeshParams2D;
                          periodic_x=true,
                          periodic_y=false,
                          output_file=nothing)
```

Generate a 2D mesh with periodic boundary conditions.

**Arguments:**
- `params` - Mesh parameters
- `periodic_x` - Enable x-direction periodicity
- `periodic_y` - Enable y-direction periodicity
- `output_file` - Output filename

#### `generate_3d_periodic_mesh`

```julia
generate_3d_periodic_mesh(params::MeshParams3D;
                          periodic_x=true,
                          periodic_y=true,
                          periodic_z=false,
                          output_file=nothing)
```

Generate a 3D mesh with periodic boundary conditions.

**Arguments:**
- `params` - Mesh parameters
- `periodic_x` - Enable x-direction periodicity
- `periodic_y` - Enable y-direction periodicity
- `periodic_z` - Enable z-direction periodicity
- `output_file` - Output filename

#### `create_stretched_mesh_3d`

```julia
create_stretched_mesh_3d(params::MeshParams3D,
                         z_stretch_factor::Float64;
                         output_file=nothing)
```

Create a 3D mesh with vertical stretching for boundary layer resolution.

**Arguments:**
- `params` - Base mesh parameters
- `z_stretch_factor` - Stretching factor (>1.0 for refinement near bottom)
- `output_file` - Output filename

## Usage Examples

### Example 1: Parametric Mesh Study

Generate a family of meshes with varying resolution:

```julia
using JexpressoMeshGenerator

resolutions = [16, 32, 64, 128]

for n in resolutions
    params = MeshParams3D(n, n, n÷2, 0.0, 10000.0, 0.0, 10000.0, 0.0, 5000.0)
    filename = "mesh_$(n)x$(n)x$(n÷2).msh"
    generate_3d_periodic_mesh(params, output_file=filename)
    println("Generated: $filename")
end
```

### Example 2: BOMEX Case Mesh

```julia
using JexpressoMeshGenerator

# Barbados Oceanographic and Meteorological Experiment
params_bomex = MeshParams3D(
    32,      # nx
    32,      # ny
    38,      # nz
    0.0,     # xmin
    6400.0,  # xmax (6.4 km)
    0.0,     # ymin
    6400.0,  # ymax (6.4 km)
    0.0,     # zmin
    3000.0   # zmax (3 km)
)

generate_3d_periodic_mesh(params_bomex,
                          periodic_x=true,
                          periodic_y=true,
                          output_file="BOMEX_32x32x38.msh")
```

### Example 3: Channel Flow with Wall-Resolved LES

```julia
using JexpressoMeshGenerator

# Turbulent channel flow with strong near-wall refinement
params_channel = MeshParams3D(
    120,    # nx - streamwise
    50,     # ny - wall-normal
    80,     # nz - spanwise
    0.0,    # xmin
    4π,     # xmax
    -1.0,   # ymin
    1.0,    # ymax
    0.0,    # zmin
    2π      # zmax
)

# 8% stretching for wall-resolved LES
create_stretched_mesh_3d(params_channel, 1.08,
                         output_file="channel_flow_120x50x80.msh")
```

### Example 4: Rayleigh-Bénard Convection

```julia
using JexpressoMeshGenerator

# 2D Rayleigh-Bénard with periodic sidewalls
params_rb = MeshParams2D(80, 80, 0.0, 2.0, 0.0, 1.0)

generate_2d_periodic_mesh(params_rb,
                          periodic_x=true,   # Periodic sidewalls
                          periodic_y=false,  # Wall top/bottom
                          output_file="rayleigh_benard_80x80.msh")
```

## Common Mesh Configurations

### Atmospheric LES (LESICP)

```julia
# 10 km × 10 km × 3.5 km domain
params = MeshParams3D(64, 64, 36, 0.0, 10240.0, 0.0, 10240.0, 0.0, 3500.0)
generate_3d_periodic_mesh(params, periodic_x=true, periodic_y=true,
                          output_file="LESICP_64x64x36.msh")
```

### Stratocumulus (DYCOMS-II)

```julia
# 6.4 km × 6.4 km × 1.5 km domain with vertical stretching
params = MeshParams3D(48, 48, 100, 0.0, 6400.0, 0.0, 6400.0, 0.0, 1500.0)
create_stretched_mesh_3d(params, 1.05, output_file="dycoms_stretched.msh")
```

### Trade-Wind Cumulus (BOMEX)

```julia
# 6.4 km × 6.4 km × 3 km domain
params = MeshParams3D(32, 32, 38, 0.0, 6400.0, 0.0, 6400.0, 0.0, 3000.0)
generate_3d_periodic_mesh(params, periodic_x=true, periodic_y=true,
                          output_file="BOMEX_32x32x38.msh")
```

## Boundary Condition Tags

The module automatically creates physical groups for boundary conditions that exactly match the reference LESICP.geo file structure.

### 3D Mesh Geometry (Reference: LESICP.geo)

All 3D meshes are generated using the same extrusion pattern as LESICP.geo:
1. **Base surface** created in x-z plane at y=ymin with points at corners
2. **Line loop** {bottom, right, top, left} forms the base surface
3. **Extrusion** in +y direction creates the 3D volume
4. **Surfaces** are automatically identified and tagged from the extrusion

**Surface ordering from GMSH extrusion:**
- Base surface (back): y=ymin (created before extrusion)
- Extruded surface (front): y=ymax (returned as first element)
- Lateral surfaces from line loop:
  - Line 1 (bottom): z=zmin → Surface tagged "MOST"
  - Line 2 (right): x=xmax → Surface tagged "right" or in "periodicx"
  - Line 3 (top): z=zmax → Surface tagged "top_wall"
  - Line 4 (left): x=xmin → Surface tagged "left" or in "periodicx"

### 2D Mesh Geometry (Reference: Standard 2D .geo files)

All 2D meshes follow this consistent pattern:
1. **Points** at corners: p1 (xmin,ymin), p2 (xmax,ymin), p3 (xmax,ymax), p4 (xmin,ymax)
2. **Lines** connecting points:
   - Line 1 (bottom): p1 → p2
   - Line 2 (right): p2 → p3
   - Line 3 (top): p3 → p4
   - Line 4 (left): p4 → p1
3. **Line loop** {left, bottom, right, top} = {4, 1, 2, 3}
4. **Surface** created from line loop

### 2D Meshes (Non-periodic)
- `"domain"` - The computational domain (surface)
- `"bottom"` - Bottom edge (Line 1)
- `"top"` - Top edge (Line 3)
- `"left"` - Left edge (Line 4)
- `"right"` - Right edge (Line 2)

### 2D Meshes (Periodic)
- `"domain"` - The computational domain (surface)
- `"periodicx"` - x-direction periodic boundaries (left + right edges)
- `"periodicy"` - y-direction periodic boundaries (bottom + top edges)
- For partially periodic: non-periodic boundaries use standard names (top, bottom, left, right)

### 3D Meshes (Periodic - LESICP-style)
- `"internal"` - The computational volume
- `"periodicy"` - y-direction periodic boundaries (back + front surfaces)
- `"periodicx"` - x-direction periodic boundaries (left + right surfaces)
- `"MOST"` - Bottom surface (z=zmin, Monin-Obukhov Similarity Theory)
- `"top_wall"` - Top surface (z=zmax)

### 3D Meshes (Non-periodic)
- `"internal"` - The computational volume
- `"back"` - y=ymin surface
- `"front"` - y=ymax surface
- `"bottom"` - z=zmin surface
- `"top"` - z=zmax surface
- `"left"` - x=xmin surface
- `"right"` - x=xmax surface

These tags are recognized by Jexpresso for applying boundary conditions and exactly match the structure of meshes generated from LESICP.geo.

## Integration with Jexpresso

The generated `.msh` files are fully compatible with Jexpresso's mesh reader. Use them in your Jexpresso simulations:

```julia
# In your Jexpresso simulation script
mesh = read_mesh("LESICP_64x64x36.msh")
```

## Tips and Best Practices

1. **Resolution guidelines:**
   - Start with coarse meshes for debugging (e.g., 8×8×8)
   - Use moderate resolution for development (e.g., 32×32×16)
   - Scale up for production runs (e.g., 128×128×64)

2. **Stretching factors:**
   - 1.0 = uniform spacing
   - 1.02-1.05 = mild stretching (stratified flows)
   - 1.05-1.10 = moderate stretching (boundary layers)
   - >1.10 = strong stretching (wall-resolved flows)

3. **Periodic boundaries:**
   - Use for homogeneous turbulence
   - Required for LES of convective boundary layers
   - Essential for spectral analysis

4. **Domain sizing:**
   - Ensure domain is large enough to contain relevant flow structures
   - For LES: domain should be several times the integral length scale
   - For convection: aspect ratio typically 2:1 to 4:1 (horizontal:vertical)

## Troubleshooting

### GMSH.jl not found
```julia
using Pkg
Pkg.add("Gmsh")
```

### Module not in load path
```julia
push!(LOAD_PATH, "/full/path/to/JexpressoMeshes/src")
```

### Mesh too coarse/fine
Adjust `nx`, `ny`, `nz` parameters in `MeshParams2D` or `MeshParams3D`.

### Boundary tags not recognized
Ensure you're using the standard tag names listed in "Boundary Condition Tags" section.

## Advanced Usage

For more advanced examples including multi-block meshes, custom boundary conditions, and complex geometries, see:
- `examples/basic_usage.jl`
- `examples/advanced_usage.jl`

## Contributing

This module is part of the Jexpresso.jl ecosystem. For questions or contributions, please refer to the main Jexpresso repository.

## License

Same as Jexpresso.jl (check the main Jexpresso repository for license details).

## References

- GMSH: C. Geuzaine and J.-F. Remacle. Gmsh: a three-dimensional finite element mesh generator with built-in pre- and post-processing facilities. International Journal for Numerical Methods in Engineering 79(11), pp. 1309-1331, 2009.
- GMSH.jl: Julia wrapper for GMSH API

## Acknowledgments

Based on the mesh generation patterns established in the JexpressoMeshes repository, this module provides a programmatic Julia interface to replace manual `.geo` scripting while maintaining full compatibility with existing Jexpresso workflows.
