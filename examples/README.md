# JexpressoMeshGenerator Examples

This directory contains example scripts demonstrating how to generate meshes for Jexpresso simulations using the JexpressoMeshGenerator.jl module.

## Quick Start

### 1. Install Dependencies

First, ensure you have GMSH.jl installed:

```julia
using Pkg
Pkg.add("Gmsh")
```

### 2. Run Examples

Navigate to the examples directory and run any example:

```bash
cd examples
julia basic_usage.jl          # Basic mesh generation examples
julia advanced_usage.jl       # Advanced atmospheric/flow examples
julia validate_2d.jl          # 2D mesh validation
julia validate_lesicp.jl      # 3D LESICP mesh validation
julia unstructured_xz_meshes.jl  # Unstructured/semi-structured meshes
```

Generated meshes will be saved in the `output_meshes/` or `validation_output/` directories.

## Available Examples

### `basic_usage.jl`
Demonstrates fundamental mesh generation:
- Simple 2D mesh (2×1 elements)
- 2D mesh with custom boundaries (10×10 unit square)
- 3D structured mesh (10×1×10 elements)
- 2D periodic mesh (20×20 elements)
- 3D LESICP-style periodic mesh (32×32×16 elements)
- 3D stretched mesh for boundary layers
- Large LESICP mesh (64×64×36 elements)

### `advanced_usage.jl`
Application-specific examples:
- BOMEX trade-wind cumulus (16×16×19)
- Rayleigh-Bénard convection (40×40)
- Channel flow with wall-resolved LES (120×31×1)
- 2D squall line (200×50)
- Multi-resolution LES meshes
- Stratified atmosphere with stretching (80×40×45)
- DYCOMS-II stratocumulus (48×48×100)

### `validate_2d.jl`
2D mesh validation:
- Simple meshes (1×1, 10×10)
- Fully periodic meshes
- Partially periodic (channel-like) meshes

### `validate_lesicp.jl`
3D LESICP mesh validation:
- Reference LESICP mesh (64×64×36)
- Small and medium test cases
- Boundary tag verification

### `unstructured_xz_meshes.jl`
Semi-structured mesh examples:
- Unstructured XZ plane with structured Y layers
- Atmospheric boundary layer applications
- High-resolution horizontal meshes

## Customizing Mesh Parameters

### Understanding MeshParams

#### MeshParams2D
```julia
MeshParams2D(
    nx,    # Number of elements in x-direction
    ny,    # Number of elements in y-direction
    xmin,  # Minimum x-coordinate (meters)
    xmax,  # Maximum x-coordinate (meters)
    ymin,  # Minimum y-coordinate (meters)
    ymax   # Maximum y-coordinate (meters)
)
```

#### MeshParams3D
```julia
MeshParams3D(
    nx,    # Number of elements in x-direction
    ny,    # Number of elements in y-direction
    nz,    # Number of elements in z-direction
    xmin,  # Minimum x-coordinate (meters)
    xmax,  # Maximum x-coordinate (meters)
    ymin,  # Minimum y-coordinate (meters)
    ymax,  # Maximum y-coordinate (meters)
    zmin,  # Minimum z-coordinate (meters)
    zmax   # Maximum z-coordinate (meters)
)
```

### How to Modify Grid Parameters

#### Example 1: Change Resolution

```julia
# Original: 20×20 mesh
params_original = MeshParams2D(20, 20, 0.0, 1.0, 0.0, 1.0)

# Finer resolution: 40×40 mesh (4× more elements)
params_fine = MeshParams2D(40, 40, 0.0, 1.0, 0.0, 1.0)

# Coarser resolution: 10×10 mesh (4× fewer elements)
params_coarse = MeshParams2D(10, 10, 0.0, 1.0, 0.0, 1.0)
```

#### Example 2: Change Domain Size

```julia
# Original: 10 km × 10 km domain
params_original = MeshParams2D(64, 64, 0.0, 10000.0, 0.0, 10000.0)

# Larger domain: 20 km × 20 km (same resolution → larger cells)
params_large = MeshParams2D(64, 64, 0.0, 20000.0, 0.0, 20000.0)

# Smaller domain: 5 km × 5 km (same resolution → smaller cells)
params_small = MeshParams2D(64, 64, 0.0, 5000.0, 0.0, 5000.0)
```

#### Example 3: Non-Square Meshes

```julia
# Rectangular domain with different resolutions
params_rect = MeshParams2D(
    100,     # nx: fine resolution in x
    50,      # ny: coarser resolution in y
    0.0,     # xmin
    10000.0, # xmax (10 km)
    0.0,     # ymin
    5000.0   # ymax (5 km)
)
# Result: 100 × 50 elements, dx=100m, dy=100m
```

#### Example 4: 3D Mesh with Anisotropic Resolution

```julia
# High horizontal resolution, moderate vertical resolution
params_3d = MeshParams3D(
    128,     # nx: high horizontal resolution in x
    128,     # ny: high horizontal resolution in y
    50,      # nz: moderate vertical resolution
    0.0,     # xmin
    10240.0, # xmax (10.24 km)
    0.0,     # ymin
    10240.0, # ymax (10.24 km)
    0.0,     # zmin
    3500.0   # zmax (3.5 km)
)
# Result: 128×128×50 elements
# Horizontal resolution: ~80 m
# Vertical resolution: ~70 m
```

### Calculating Element Size

The element size (Δx, Δy, Δz) is calculated as:

```
Δx = (xmax - xmin) / nx
Δy = (ymax - ymin) / ny
Δz = (zmax - zmin) / nz
```

**Example:**
```julia
params = MeshParams3D(64, 64, 36, 0.0, 10240.0, 0.0, 10240.0, 0.0, 3500.0)

# Element sizes:
Δx = (10240.0 - 0.0) / 64 = 160 m
Δy = (10240.0 - 0.0) / 64 = 160 m
Δz = (3500.0 - 0.0) / 36 ≈ 97.2 m
```

### Guidelines for Choosing Parameters

#### Resolution Guidelines

| Application | Typical Resolution | Element Count Range |
|-------------|-------------------|---------------------|
| Quick tests | 5×5 to 10×10 | 25-100 |
| Development | 16×16 to 32×32 | 256-1024 |
| Production 2D | 64×64 to 128×128 | 4k-16k |
| Production 3D | 32³ to 128³ | 32k-2M |
| High-res LES | 256³ to 512³ | 16M-134M |

#### Domain Size Guidelines

**Atmospheric Simulations:**
- **Shallow convection (BOMEX):** 6.4 km × 6.4 km × 3 km
- **Deep convection (LESICP):** 10 km × 10 km × 3.5 km
- **Stratocumulus (DYCOMS):** 6.4 km × 6.4 km × 1.5 km
- **Squall lines:** 100 km × 20 km (2D)

**Fluid Dynamics:**
- **Channel flow:** Lx = 2πh to 4πh, Ly = 2h, Lz = πh to 2πh
- **Rayleigh-Bénard:** Aspect ratio 1:1 to 4:1 (horizontal:vertical)
- **Turbulent boundary layer:** Domain should contain multiple large eddies

#### Vertical Stretching

For meshes with boundary layers, use vertical stretching:

```julia
params = MeshParams3D(64, 64, 50, 0.0, 10000.0, 0.0, 10000.0, 0.0, 2000.0)

# Stretching factor > 1.0 refines mesh near bottom
create_stretched_mesh_3d(params, 1.05, output_file="stretched.msh")

# Stretching factors:
# 1.00 = uniform spacing
# 1.02-1.05 = mild stretching (stratified flows)
# 1.05-1.10 = moderate stretching (boundary layers)
# >1.10 = strong stretching (wall-resolved flows)
```

## Common Workflow Examples

### Workflow 1: Resolution Study

Generate meshes with increasing resolution:

```julia
using JexpressoMeshGenerator

resolutions = [16, 32, 64, 128]
domain_size = 10000.0  # 10 km

for n in resolutions
    params = MeshParams2D(n, n, 0.0, domain_size, 0.0, domain_size)
    filename = "mesh_$(n)x$(n).msh"
    generate_2d_structured_mesh(params, output_file=filename)

    # Calculate element size
    dx = domain_size / n
    println("Generated $filename: $(n)×$(n) elements, Δx = $(dx) m")
end
```

### Workflow 2: Parametric Domain Study

Vary domain size while keeping resolution constant:

```julia
using JexpressoMeshGenerator

domain_sizes = [5000.0, 10000.0, 15000.0, 20000.0]  # km
resolution = 64

for Lx in domain_sizes
    params = MeshParams2D(resolution, resolution, 0.0, Lx, 0.0, Lx)
    filename = "mesh_$(Int(Lx/1000))km.msh"
    generate_2d_structured_mesh(params, output_file=filename)

    dx = Lx / resolution
    println("Domain: $(Lx/1000) km, Δx = $(dx) m")
end
```

### Workflow 3: Custom LESICP Configuration

Create your own LESICP-style mesh:

```julia
using JexpressoMeshGenerator

# Define your domain
Lx = 15000.0  # 15 km horizontal extent
Ly = 15000.0  # 15 km horizontal extent
Lz = 4000.0   # 4 km vertical extent

# Define resolution
nx = 96   # Horizontal resolution
ny = 96   # Horizontal resolution
nz = 48   # Vertical resolution

# Calculate element sizes
println("Element sizes:")
println("  Δx = $(Lx/nx) m")
println("  Δy = $(Ly/ny) m")
println("  Δz = $(Lz/nz) m")

# Create mesh
params = MeshParams3D(nx, ny, nz, 0.0, Lx, 0.0, Ly, 0.0, Lz)
generate_3d_periodic_mesh(
    params,
    periodic_x = true,
    periodic_y = true,
    output_file = "custom_LESICP_$(nx)x$(ny)x$(nz).msh"
)
```

## Output Files

All generated meshes are saved as GMSH `.msh` files compatible with Jexpresso. The files contain:

- **Node coordinates**: 3D positions of all mesh nodes
- **Element connectivity**: How nodes connect to form elements
- **Physical groups**: Boundary condition tags (e.g., "top", "bottom", "MOST", "periodicx")

### Using Generated Meshes in Jexpresso

```julia
# In your Jexpresso simulation script
mesh = read_mesh("output_meshes/LESICP_64x64x36.msh")

# The mesh object contains all geometry and boundary information
# Boundary tags match those in the mesh generator
```

## Tips and Best Practices

### Memory Considerations

Element count grows rapidly with resolution:
- 2D: Elements = nx × ny
- 3D: Elements = nx × ny × nz

**Example:**
- 64×64×36 mesh = 147,456 elements ✓ (reasonable)
- 128×128×72 mesh = 1,179,648 elements ⚠ (large)
- 256×256×144 mesh = 9,437,184 elements ❌ (very large)

### Performance Tips

1. **Start coarse**: Begin with 16×16 or 32×32 for testing
2. **Refine gradually**: Double resolution systematically
3. **Check convergence**: Ensure solutions are grid-independent
4. **Use stretching**: Refine where needed, coarsen elsewhere

### Common Issues

**Issue: Mesh generation is slow**
- Solution: Reduce resolution or use structured meshes instead of unstructured

**Issue: Jexpresso won't read the mesh**
- Solution: Check that output file exists and isn't corrupted
- Solution: Verify boundary tag names match Jexpresso expectations

**Issue: Simulation crashes with large mesh**
- Solution: Reduce resolution or increase available memory
- Solution: Use domain decomposition for parallel computing

## Getting Help

- **Documentation**: See [MESH_GENERATOR_README.md](../MESH_GENERATOR_README.md)
- **Quick start**: See [QUICKSTART.md](../QUICKSTART.md)
- **Reference meshes**: Check `meshes/gmsh_grids/*.geo` for examples

## Summary of Available Functions

### 2D Meshes
```julia
generate_2d_structured_mesh(params)      # Fully structured
generate_2d_periodic_mesh(params)        # Periodic boundaries
generate_2d_unstructured_mesh(params)    # Semi-structured
```

### 3D Meshes
```julia
generate_3d_structured_mesh(params)      # Fully structured
generate_3d_periodic_mesh(params)        # Periodic (LESICP-style)
create_stretched_mesh_3d(params, factor) # Vertical stretching
generate_3d_unstructured_xz_mesh(params) # Unstructured XZ plane
```

Happy meshing! 🎉
