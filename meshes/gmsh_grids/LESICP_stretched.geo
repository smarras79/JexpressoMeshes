//-----------------------------------------------------------------------
// Gmsh script for a 3D box with one-sided stretching in the Z-direction
//-----------------------------------------------------------------------

// :: MESH PARAMETERS ::
// Domain dimensions
Lx = 5120.0;
Ly = 2560.0;
Lz = 4000.0;

// Number of elements in each direction
Nx = 64;
Ny = 32;
Nz = 24;

// Stretching ratio for the Z-direction.
// > 1 means cells get larger away from the line's start point.
// < 1 means cells get smaller away from the line's start point.
stretch_ratio = 1.05;

//-----------------------------------------------------------------------
// :: GEOMETRY DEFINITION ::
//-----------------------------------------------------------------------

// Define corner points
// Bottom plane (z=0)
Point(1) = {0,  0,  0,  1.0};
Point(2) = {Lx, 0,  0,  1.0};
Point(3) = {Lx, Ly, 0,  1.0};
Point(4) = {0,  Ly, 0,  1.0};

// Top plane (z=Lz)
Point(5) = {0,  0,  Lz, 1.0};
Point(6) = {Lx, 0,  Lz, 1.0};
Point(7) = {Lx, Ly, Lz, 1.0};
Point(8) = {0,  Ly, Lz, 1.0};

// Define lines connecting the points
// Bottom lines
Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

// Vertical lines (IMPORTANT: Defined from bottom to top)
Line(5) = {1, 5};
Line(6) = {2, 6};
Line(7) = {3, 7};
Line(8) = {4, 8};

// Top lines
Line(9)  = {5, 6};
Line(10) = {6, 7};
Line(11) = {7, 8};
Line(12) = {8, 5};

// Define surfaces
Line Loop(1) = {1, 6, -9, -5};  Plane Surface(1) = {1}; // Front (constant-y)
Line Loop(2) = {2, 7, -10, -6}; Plane Surface(2) = {2}; // Right (constant-x)
Line Loop(3) = {3, 8, -11, -7}; Plane Surface(3) = {3}; // Back (constant-y)
Line Loop(4) = {4, 5, -12, -8}; Plane Surface(4) = {4}; // Left (constant-x)
Line Loop(5) = {1, 2, 3, 4};    Plane Surface(5) = {5}; // Bottom
Line Loop(6) = {9, 10, 11, 12}; Plane Surface(6) = {6}; // Top

// Define volume
Surface Loop(1) = {1, 2, 3, 4, 5, 6};
Volume(1) = {1};

//-----------------------------------------------------------------------
// :: PHYSICAL GROUPS (BOUNDARY CONDITIONS) ::
//-----------------------------------------------------------------------

// Physical names are assigned to surfaces to identify boundaries.
// The string in quotes is the name the solver will see.

// 1. Bottom and Top walls
Physical Surface("MOST") = {5};      // Bottom surface
Physical Surface("top_wall") = {6};   // Top surface

// 2. Periodic vertical surfaces
Physical Surface("periodicx") = {4, 2}; // Left and Right surfaces
Physical Surface("periodicy") = {1, 3}; // Front and Back surfaces

//-----------------------------------------------------------------------
// :: MESHING INSTRUCTIONS (TRANSFINITE) ::
//-----------------------------------------------------------------------

// Set transfinite lines
// Uniform distribution in X and Y
Transfinite Line {1, 3, 9, 11} = Nx + 1;
Transfinite Line {2, 4, 10, 12} = Ny + 1;

// Apply stretching progression to vertical lines
Transfinite Line {5, 6, 7, 8} = Nz + 1 Using Progression stretch_ratio;

// Set transfinite surfaces and volume
Transfinite Surface {1, 2, 3, 4, 5, 6};
Transfinite Volume {1};

// Use the transfinite algorithm with recombination for a hexahedral mesh
Mesh.RecombineAll = 1;