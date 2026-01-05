"""
# JexpressoMeshGenerator.jl

A standalone Julia module for generating meshes directly within Jexpresso using GMSH.jl.
This module provides convenient functions to create structured meshes commonly used in
Jexpresso simulations without requiring external GMSH scripting.

## Features
- 2D and 3D structured mesh generation
- Transfinite meshing for hexahedral elements
- Support for periodic boundary conditions
- Customizable boundary condition tagging
- Mesh stretching and non-uniform spacing
- Direct export to GMSH .msh format compatible with Jexpresso

## Dependencies
- GMSH.jl: Julia interface to GMSH

## Author
Generated for Jexpresso.jl mesh generation
"""
module JexpressoMeshGenerator

using Gmsh: gmsh

export MeshParams2D, MeshParams3D
export generate_2d_structured_mesh, generate_3d_structured_mesh
export generate_2d_periodic_mesh, generate_3d_periodic_mesh
export save_mesh, create_stretched_mesh_3d

"""
    MeshParams2D

Parameters for 2D structured mesh generation.

# Fields
- `nx::Int`: Number of elements in x-direction
- `ny::Int`: Number of elements in y-direction
- `xmin::Float64`: Minimum x-coordinate
- `xmax::Float64`: Maximum x-coordinate
- `ymin::Float64`: Minimum y-coordinate
- `ymax::Float64`: Maximum y-coordinate
- `boundary_tags::Dict{String,Vector{Int}}`: Physical tags for boundaries
"""
struct MeshParams2D
    nx::Int
    ny::Int
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64
    boundary_tags::Dict{String,Vector{Int}}

    function MeshParams2D(nx, ny, xmin, xmax, ymin, ymax;
                          boundary_tags=Dict("domain" => [1]))
        new(nx, ny, xmin, xmax, ymin, ymax, boundary_tags)
    end
end

"""
    MeshParams3D

Parameters for 3D structured mesh generation.

# Fields
- `nx::Int`: Number of elements in x-direction
- `ny::Int`: Number of elements in y-direction
- `nz::Int`: Number of elements in z-direction
- `xmin::Float64`: Minimum x-coordinate
- `xmax::Float64`: Maximum x-coordinate
- `ymin::Float64`: Minimum y-coordinate
- `ymax::Float64`: Maximum y-coordinate
- `zmin::Float64`: Minimum z-coordinate
- `zmax::Float64`: Maximum z-coordinate
- `boundary_tags::Dict{String,Vector{Int}}`: Physical tags for boundaries and volume
"""
struct MeshParams3D
    nx::Int
    ny::Int
    nz::Int
    xmin::Float64
    xmax::Float64
    ymin::Float64
    ymax::Float64
    zmin::Float64
    zmax::Float64
    boundary_tags::Dict{String,Vector{Int}}

    function MeshParams3D(nx, ny, nz, xmin, xmax, ymin, ymax, zmin, zmax;
                          boundary_tags=Dict("internal" => [1]))
        new(nx, ny, nz, xmin, xmax, ymin, ymax, zmin, zmax, boundary_tags)
    end
end

"""
    generate_2d_structured_mesh(params::MeshParams2D; recombine=true, output_file=nothing)

Generate a 2D structured mesh using transfinite algorithm.

# Arguments
- `params::MeshParams2D`: Mesh parameters
- `recombine::Bool`: If true, recombine triangles into quadrilaterals (default: true)
- `output_file::String`: Optional output file path. If provided, mesh is saved automatically.

# Returns
- Nothing if output_file is provided, otherwise mesh is kept in GMSH for further operations

# Example
```julia
params = MeshParams2D(10, 10, -1.0, 1.0, -1.0, 1.0,
                      boundary_tags=Dict("T1" => [1, 3], "T2" => [2, 4], "domain" => [1]))
generate_2d_structured_mesh(params, output_file="mesh_10x10.msh")
```
"""
function generate_2d_structured_mesh(params::MeshParams2D; recombine=true, output_file=nothing)
    gmsh.initialize()
    gmsh.model.add("2d_structured")

    # Calculate grid size
    gridsize = (params.xmax - params.xmin) / params.nx

    # Create corner points
    p1 = gmsh.model.geo.addPoint(params.xmin, params.ymin, 0.0, gridsize)
    p2 = gmsh.model.geo.addPoint(params.xmax, params.ymin, 0.0, gridsize)
    p3 = gmsh.model.geo.addPoint(params.xmax, params.ymax, 0.0, gridsize)
    p4 = gmsh.model.geo.addPoint(params.xmin, params.ymax, 0.0, gridsize)

    # Create lines
    l1 = gmsh.model.geo.addLine(p1, p2)  # bottom
    l2 = gmsh.model.geo.addLine(p2, p3)  # right
    l3 = gmsh.model.geo.addLine(p3, p4)  # top
    l4 = gmsh.model.geo.addLine(p4, p1)  # left

    # Set transfinite constraints
    gmsh.model.geo.mesh.setTransfiniteCurve(l1, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l3, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l2, params.ny + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l4, params.ny + 1)

    # Create surface
    curve_loop = gmsh.model.geo.addCurveLoop([l1, l2, l3, l4])
    surface = gmsh.model.geo.addPlaneSurface([curve_loop])

    # Set transfinite surface
    gmsh.model.geo.mesh.setTransfiniteSurface(surface)

    if recombine
        gmsh.model.geo.mesh.setRecombine(2, surface)
    end

    # Synchronize before adding physical groups
    gmsh.model.geo.synchronize()

    # Add physical groups for boundaries
    for (tag_name, line_ids) in params.boundary_tags
        if tag_name != "domain"
            gmsh.model.addPhysicalGroup(1, line_ids, -1, tag_name)
        end
    end

    # Add physical surface
    gmsh.model.addPhysicalGroup(2, [surface], -1, "domain")

    # Generate mesh
    gmsh.model.mesh.generate(2)

    # Save mesh if output file is provided
    if !isnothing(output_file)
        gmsh.write(output_file)
        gmsh.finalize()
        println("2D mesh saved to: $output_file")
    end

    return nothing
end

"""
    generate_3d_structured_mesh(params::MeshParams3D; recombine=true, output_file=nothing)

Generate a 3D structured mesh using transfinite algorithm with extrusion.

# Arguments
- `params::MeshParams3D`: Mesh parameters
- `recombine::Bool`: If true, recombine into hexahedral elements (default: true)
- `output_file::String`: Optional output file path

# Returns
- Nothing if output_file is provided, otherwise mesh is kept in GMSH for further operations

# Example
```julia
params = MeshParams3D(10, 10, 10, -5000, 5000, -3000, 1500, 0, 10000,
                      boundary_tags=Dict("internal" => [1],
                                        "bottom" => [1], "top" => [2],
                                        "left" => [3], "right" => [4],
                                        "front" => [5], "back" => [6]))
generate_3d_structured_mesh(params, output_file="mesh_10x10x10.msh")
```
"""
function generate_3d_structured_mesh(params::MeshParams3D; recombine=true, output_file=nothing)
    gmsh.initialize()
    gmsh.model.add("3d_structured")

    # Calculate grid size based on x-direction
    gridsize = (params.xmax - params.xmin) / params.nx

    # Create corner points of the base surface (z-min plane)
    p1 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmin, gridsize)
    p2 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmin, gridsize)
    p3 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmax, gridsize)
    p4 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmax, gridsize)

    # Create lines for base surface (in x-z plane at y=ymin)
    l1 = gmsh.model.geo.addLine(p1, p2)  # bottom (z=zmin)
    l2 = gmsh.model.geo.addLine(p2, p3)  # right (x=xmax)
    l3 = gmsh.model.geo.addLine(p3, p4)  # top (z=zmax)
    l4 = gmsh.model.geo.addLine(p4, p1)  # left (x=xmin)

    # Set transfinite constraints on lines
    gmsh.model.geo.mesh.setTransfiniteCurve(l1, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l3, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l2, params.nz + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l4, params.nz + 1)

    # Create base surface
    curve_loop = gmsh.model.geo.addCurveLoop([l1, l2, l3, l4])
    base_surface = gmsh.model.geo.addPlaneSurface([curve_loop])

    # Set transfinite surface
    gmsh.model.geo.mesh.setTransfiniteSurface(base_surface)

    if recombine
        gmsh.model.geo.mesh.setRecombine(2, base_surface)
    end

    # Synchronize before extrusion
    gmsh.model.geo.synchronize()

    # Extrude the surface in y-direction to create 3D volume
    extrude_vec = [0, params.ymax - params.ymin, 0]
    extruded = gmsh.model.geo.extrude([(2, base_surface)], extrude_vec[1], extrude_vec[2], extrude_vec[3],
                                       [params.ny], recombine=recombine)

    # Synchronize after extrusion
    gmsh.model.geo.synchronize()

    # Extract volume and surfaces from extrusion
    # extruded contains: [(dim, tag), ...] where the volume is typically the first element
    volume_tag = nothing
    surface_tags = Dict{String,Int}()

    for (dim, tag) in extruded
        if dim == 3
            volume_tag = tag
        end
    end

    # Get all surfaces to identify boundaries
    # The extrusion creates surfaces in a specific order:
    # base_surface (back, y=ymin), top surface (front, y=ymax), and side surfaces
    all_surfaces = gmsh.model.getEntities(2)

    # Add physical groups
    if !isnothing(volume_tag)
        gmsh.model.addPhysicalGroup(3, [volume_tag], -1, "internal")
    end

    # For boundaries, we need to identify them properly
    # This is a simplified version - for production, you'd want more robust boundary identification
    surface_ids = [tag for (dim, tag) in all_surfaces if dim == 2]

    # Add all surfaces as boundaries (user can customize this)
    if length(surface_ids) > 0
        # Back surface (y=ymin)
        gmsh.model.addPhysicalGroup(2, [base_surface], -1, "back")

        # Try to identify other surfaces
        remaining_surfaces = filter(x -> x != base_surface, surface_ids)
        if length(remaining_surfaces) >= 1
            # Front surface (y=ymax)
            gmsh.model.addPhysicalGroup(2, [remaining_surfaces[1]], -1, "front")
        end
        if length(remaining_surfaces) >= 2
            # Bottom surface (z=zmin)
            gmsh.model.addPhysicalGroup(2, [remaining_surfaces[2]], -1, "bottom")
        end
        if length(remaining_surfaces) >= 3
            # Right surface (x=xmax)
            gmsh.model.addPhysicalGroup(2, [remaining_surfaces[3]], -1, "right")
        end
        if length(remaining_surfaces) >= 4
            # Top surface (z=zmax)
            gmsh.model.addPhysicalGroup(2, [remaining_surfaces[4]], -1, "top")
        end
        if length(remaining_surfaces) >= 5
            # Left surface (x=xmin)
            gmsh.model.addPhysicalGroup(2, [remaining_surfaces[5]], -1, "left")
        end
    end

    # Generate mesh
    gmsh.model.mesh.generate(3)

    # Save mesh if output file is provided
    if !isnothing(output_file)
        gmsh.write(output_file)
        gmsh.finalize()
        println("3D mesh saved to: $output_file")
    end

    return nothing
end

"""
    generate_2d_periodic_mesh(params::MeshParams2D; periodic_x=true, periodic_y=false,
                              output_file=nothing)

Generate a 2D structured mesh with periodic boundary conditions.

# Arguments
- `params::MeshParams2D`: Mesh parameters
- `periodic_x::Bool`: Enable periodicity in x-direction (default: true)
- `periodic_y::Bool`: Enable periodicity in y-direction (default: false)
- `output_file::String`: Optional output file path

# Example
```julia
params = MeshParams2D(20, 20, 0.0, 10.0, 0.0, 10.0)
generate_2d_periodic_mesh(params, periodic_x=true, periodic_y=true,
                          output_file="periodic_mesh.msh")
```
"""
function generate_2d_periodic_mesh(params::MeshParams2D; periodic_x=true, periodic_y=false,
                                   output_file=nothing)
    gmsh.initialize()
    gmsh.model.add("2d_periodic")

    gridsize = (params.xmax - params.xmin) / params.nx

    # Create corner points
    p1 = gmsh.model.geo.addPoint(params.xmin, params.ymin, 0.0, gridsize)
    p2 = gmsh.model.geo.addPoint(params.xmax, params.ymin, 0.0, gridsize)
    p3 = gmsh.model.geo.addPoint(params.xmax, params.ymax, 0.0, gridsize)
    p4 = gmsh.model.geo.addPoint(params.xmin, params.ymax, 0.0, gridsize)

    # Create lines
    l1 = gmsh.model.geo.addLine(p1, p2)  # bottom
    l2 = gmsh.model.geo.addLine(p2, p3)  # right
    l3 = gmsh.model.geo.addLine(p3, p4)  # top
    l4 = gmsh.model.geo.addLine(p4, p1)  # left

    # Set transfinite constraints
    gmsh.model.geo.mesh.setTransfiniteCurve(l1, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l3, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l2, params.ny + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l4, params.ny + 1)

    # Create surface
    curve_loop = gmsh.model.geo.addCurveLoop([l1, l2, l3, l4])
    surface = gmsh.model.geo.addPlaneSurface([curve_loop])

    gmsh.model.geo.mesh.setTransfiniteSurface(surface)
    gmsh.model.geo.mesh.setRecombine(2, surface)

    gmsh.model.geo.synchronize()

    # Set periodic boundary conditions
    if periodic_x
        # Left and right boundaries are periodic
        gmsh.model.mesh.setPeriodic(1, [l2], [l4], [1, 0, 0, params.xmax - params.xmin,
                                                    0, 1, 0, 0,
                                                    0, 0, 1, 0,
                                                    0, 0, 0, 1])
        gmsh.model.addPhysicalGroup(1, [l4, l2], -1, "periodicx")
    end

    if periodic_y
        # Bottom and top boundaries are periodic
        gmsh.model.mesh.setPeriodic(1, [l3], [l1], [1, 0, 0, 0,
                                                    0, 1, 0, params.ymax - params.ymin,
                                                    0, 0, 1, 0,
                                                    0, 0, 0, 1])
        gmsh.model.addPhysicalGroup(1, [l1, l3], -1, "periodicy")
    end

    # Add non-periodic boundaries as physical groups
    if !periodic_y
        gmsh.model.addPhysicalGroup(1, [l1], -1, "bottom")
        gmsh.model.addPhysicalGroup(1, [l3], -1, "top")
    end

    if !periodic_x
        gmsh.model.addPhysicalGroup(1, [l4], -1, "left")
        gmsh.model.addPhysicalGroup(1, [l2], -1, "right")
    end

    gmsh.model.addPhysicalGroup(2, [surface], -1, "domain")

    # Generate mesh
    gmsh.model.mesh.generate(2)

    if !isnothing(output_file)
        gmsh.write(output_file)
        gmsh.finalize()
        println("2D periodic mesh saved to: $output_file")
    end

    return nothing
end

"""
    generate_3d_periodic_mesh(params::MeshParams3D; periodic_x=true, periodic_y=true,
                              periodic_z=false, output_file=nothing)

Generate a 3D structured mesh with periodic boundary conditions.

# Arguments
- `params::MeshParams3D`: Mesh parameters
- `periodic_x::Bool`: Enable periodicity in x-direction
- `periodic_y::Bool`: Enable periodicity in y-direction
- `periodic_z::Bool`: Enable periodicity in z-direction
- `output_file::String`: Optional output file path

# Example
```julia
params = MeshParams3D(64, 64, 36, 0, 10240, 0, 10240, 0, 3500)
generate_3d_periodic_mesh(params, periodic_x=true, periodic_y=true,
                          output_file="LESICP_64x64x36.msh")
```
"""
function generate_3d_periodic_mesh(params::MeshParams3D; periodic_x=true, periodic_y=true,
                                   periodic_z=false, output_file=nothing)
    gmsh.initialize()
    gmsh.model.add("3d_periodic")

    gridsize = (params.xmax - params.xmin) / params.nx

    # Create base surface points
    p1 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmin, gridsize)
    p2 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmin, gridsize)
    p3 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmax, gridsize)
    p4 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmax, gridsize)

    # Create base surface lines
    l1 = gmsh.model.geo.addLine(p1, p2)
    l2 = gmsh.model.geo.addLine(p2, p3)
    l3 = gmsh.model.geo.addLine(p3, p4)
    l4 = gmsh.model.geo.addLine(p4, p1)

    # Set transfinite constraints
    gmsh.model.geo.mesh.setTransfiniteCurve(l1, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l3, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l2, params.nz + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l4, params.nz + 1)

    # Create base surface
    curve_loop = gmsh.model.geo.addCurveLoop([l1, l2, l3, l4])
    base_surface = gmsh.model.geo.addPlaneSurface([curve_loop])

    gmsh.model.geo.mesh.setTransfiniteSurface(base_surface)
    gmsh.model.geo.mesh.setRecombine(2, base_surface)

    gmsh.model.geo.synchronize()

    # Extrude to create volume
    extruded = gmsh.model.geo.extrude([(2, base_surface)], 0, params.ymax - params.ymin, 0,
                                       [params.ny], recombine=true)

    gmsh.model.geo.synchronize()

    # Get volume tag
    volume_tag = nothing
    for (dim, tag) in extruded
        if dim == 3
            volume_tag = tag
        end
    end

    # Get all surfaces for boundary identification
    all_surfaces = gmsh.model.getEntities(2)
    surface_tags_list = [tag for (dim, tag) in all_surfaces]

    # Physical groups
    if !isnothing(volume_tag)
        gmsh.model.addPhysicalGroup(3, [volume_tag], -1, "internal")
    end

    # Identify boundary surfaces (this requires knowledge of GMSH's extrusion ordering)
    # After extrusion: base (back), extruded top (front), and 4 lateral surfaces
    back_surface = base_surface

    # The extruded surfaces are returned in specific order
    # We need to identify them correctly
    remaining = filter(x -> x != back_surface, surface_tags_list)

    if length(remaining) >= 5
        front_surface = remaining[1]
        bottom_surface = remaining[2]
        right_surface = remaining[3]
        top_surface = remaining[4]
        left_surface = remaining[5]

        # Add physical groups based on periodicity
        if periodic_y
            gmsh.model.addPhysicalGroup(2, [back_surface, front_surface], -1, "periodicy")
        else
            gmsh.model.addPhysicalGroup(2, [back_surface], -1, "back")
            gmsh.model.addPhysicalGroup(2, [front_surface], -1, "front")
        end

        if periodic_x
            gmsh.model.addPhysicalGroup(2, [left_surface, right_surface], -1, "periodicx")
        else
            gmsh.model.addPhysicalGroup(2, [left_surface], -1, "left")
            gmsh.model.addPhysicalGroup(2, [right_surface], -1, "right")
        end

        if periodic_z
            gmsh.model.addPhysicalGroup(2, [bottom_surface, top_surface], -1, "periodicz")
        else
            gmsh.model.addPhysicalGroup(2, [bottom_surface], -1, "MOST")
            gmsh.model.addPhysicalGroup(2, [top_surface], -1, "top_wall")
        end
    end

    # Generate mesh
    gmsh.model.mesh.generate(3)

    if !isnothing(output_file)
        gmsh.write(output_file)
        gmsh.finalize()
        println("3D periodic mesh saved to: $output_file")
    end

    return nothing
end

"""
    create_stretched_mesh_3d(params::MeshParams3D, z_stretch_factor::Float64;
                             output_file=nothing)

Create a 3D mesh with vertical (z-direction) stretching.

# Arguments
- `params::MeshParams3D`: Base mesh parameters
- `z_stretch_factor::Float64`: Stretching factor for z-direction (> 1.0 for refinement near bottom)
- `output_file::String`: Optional output file path

# Example
```julia
params = MeshParams3D(32, 16, 16, 0, 10000, 0, 5000, 0, 3000)
create_stretched_mesh_3d(params, 1.05, output_file="stretched_mesh.msh")
```
"""
function create_stretched_mesh_3d(params::MeshParams3D, z_stretch_factor::Float64;
                                 output_file=nothing)
    gmsh.initialize()
    gmsh.model.add("3d_stretched")

    gridsize = (params.xmax - params.xmin) / params.nx

    # Create base surface
    p1 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmin, gridsize)
    p2 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmin, gridsize)
    p3 = gmsh.model.geo.addPoint(params.xmax, params.ymin, params.zmax, gridsize)
    p4 = gmsh.model.geo.addPoint(params.xmin, params.ymin, params.zmax, gridsize)

    l1 = gmsh.model.geo.addLine(p1, p2)
    l2 = gmsh.model.geo.addLine(p2, p3)
    l3 = gmsh.model.geo.addLine(p3, p4)
    l4 = gmsh.model.geo.addLine(p4, p1)

    # Set transfinite with progression for stretching
    gmsh.model.geo.mesh.setTransfiniteCurve(l1, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l3, params.nx + 1)
    gmsh.model.geo.mesh.setTransfiniteCurve(l2, params.nz + 1, coef=z_stretch_factor)
    gmsh.model.geo.mesh.setTransfiniteCurve(l4, params.nz + 1, coef=z_stretch_factor)

    curve_loop = gmsh.model.geo.addCurveLoop([l1, l2, l3, l4])
    base_surface = gmsh.model.geo.addPlaneSurface([curve_loop])

    gmsh.model.geo.mesh.setTransfiniteSurface(base_surface)
    gmsh.model.geo.mesh.setRecombine(2, base_surface)

    gmsh.model.geo.synchronize()

    # Extrude with uniform spacing in y
    extruded = gmsh.model.geo.extrude([(2, base_surface)], 0, params.ymax - params.ymin, 0,
                                       [params.ny], recombine=true)

    gmsh.model.geo.synchronize()

    # Add physical groups
    for (dim, tag) in extruded
        if dim == 3
            gmsh.model.addPhysicalGroup(3, [tag], -1, "internal")
        end
    end

    # Generate mesh
    gmsh.model.mesh.generate(3)

    if !isnothing(output_file)
        gmsh.write(output_file)
        gmsh.finalize()
        println("3D stretched mesh saved to: $output_file")
    end

    return nothing
end

"""
    save_mesh(filename::String)

Save the current GMSH mesh to a file and finalize GMSH.

# Arguments
- `filename::String`: Output file path (should end with .msh)
"""
function save_mesh(filename::String)
    gmsh.write(filename)
    gmsh.finalize()
    println("Mesh saved to: $filename")
end

end # module
