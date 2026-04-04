// -----------------------------------------------------------------------------
// Gmsh .geo script for a Cubed Sphere
// Generates a 2D spherical shell meshed with structured quadrilateral elements.
// -----------------------------------------------------------------------------

// -- Parameters --
R = 1.0;           // Radius of the spherical shell
N = 10;            // Number of elements along each edge of the cube patches
a = R / Sqrt(3);   // Cartesian coordinate for a cube's corners on a sphere

// -- Center Point --
Point(9) = {0, 0, 0};

// -- 8 Corners of the Cube Projected onto the Sphere --
Point(1) = { a,  a,  a};
Point(2) = {-a,  a,  a};
Point(3) = {-a, -a,  a};
Point(4) = { a, -a,  a};
Point(5) = { a,  a, -a};
Point(6) = {-a,  a, -a};
Point(7) = {-a, -a, -a};
Point(8) = { a, -a, -a};

// -- 12 Circular Arcs (Edges of the patches) --
// Top Face Edges
Circle(1) = {1, 9, 2};
Circle(2) = {2, 9, 3};
Circle(3) = {3, 9, 4};
Circle(4) = {4, 9, 1};

// Bottom Face Edges
Circle(5) = {5, 9, 6};
Circle(6) = {6, 9, 7};
Circle(7) = {7, 9, 8};
Circle(8) = {8, 9, 5};

// Vertical Edges
Circle(9)  = {1, 9, 5};
Circle(10) = {2, 9, 6};
Circle(11) = {3, 9, 7};
Circle(12) = {4, 9, 8};

// -- 6 Curve Loops (Faces of the cube) --
// The negative signs ensure correct orientation of the loops
Curve Loop(1) = {1, 2, 3, 4};           // Top
Curve Loop(2) = {5, 6, 7, 8};           // Bottom
Curve Loop(3) = {1, 10, -5, -9};        // Front (+y)
Curve Loop(4) = {2, 11, -6, -10};       // Left (-x)
Curve Loop(5) = {3, 12, -7, -11};       // Back (-y)
Curve Loop(6) = {4, 9, -8, -12};        // Right (+x)

// -- Surfaces --
Surface(1) = {1};
Surface(2) = {2};
Surface(3) = {3};
Surface(4) = {4};
Surface(5) = {5};
Surface(6) = {6};

// -- Transfinite Meshing --
// Forces a structured grid of size N x N on every patch
Transfinite Curve {1:12} = N + 1;
Transfinite Surface {1:6};

// -- Recombination --
// Converts the default triangular mesh into quadrilaterals
Recombine Surface {1:6};

// -- Physical Groups --
// Group all surfaces together for easy boundary condition assignment or exporting
Physical Surface("Spherical_Shell", 100) = {1:6};