// =====================================================================
// 2D rectangular domain (3 x 2) with a circular hole (e.g. a cylinder).
//
// Key point: this uses the OpenCASCADE kernel and defines the circle
// directly from (x, y, z, radius). With OCC there is NO center-point
// entity in the geometry at all, so the circle's center is never meshed
// and never written to the .msh file.
// =====================================================================

SetFactory("OpenCASCADE");

// Mesh size
lc = 0.25;

// Domain boundaries
xmin = 0.0;
xmax = 3.0;
ymin = 0.0;
ymax = 2.0;

// Circle parameters
radius = 0.2;
xc = 0.8;
yc = 1.0;

// --- Rectangle corner points ---
Point(1) = {xmin, ymin, 0, lc};
Point(2) = {xmax, ymin, 0, lc};
Point(3) = {xmax, ymax, 0, lc};
Point(4) = {xmin, ymax, 0, lc};

// --- Rectangle edges ---
Line(1) = {1, 2};   // bottom
Line(2) = {2, 3};   // right  (outflow)
Line(3) = {3, 4};   // top
Line(4) = {4, 1};   // left   (inflow)

// --- Full circle as a single OCC curve (no center point!) ---
Circle(5) = {xc, yc, 0, radius, 0, 2*Pi};

// --- Loops: outer rectangle + inner circular hole ---
Curve Loop(1) = {1, 2, 3, 4};
Curve Loop(2) = {5};

// --- Surface = rectangle minus the disk ---
Plane Surface(1) = {1, 2};

// Apply mesh size on the nodes that OCC created for the circle curve
MeshSize{ PointsOf{ Curve{5}; } } = lc;

// --- All-quad unstructured mesh settings ---
// NOTE: do NOT use the "full-quad" algorithms (2 or 3). They guarantee
// all-quads by inserting edge-midpoint nodes, which along straight edges
// land collinear with their neighbors -> quads with a ~180 deg corner
// (the "3 aligned points" defect). Plain blossom (1) merges triangle
// pairs without inserting midpoints, and topology optimization + smoothing
// clean up the remainder so the result is still 100% quads.
Mesh.Algorithm                  = 8;  // Frontal-Delaunay for quads
Mesh.RecombinationAlgorithm     = 1;  // Blossom (no midpoint insertion)
Mesh.RecombineOptimizeTopology  = 5;  // topological clean-up passes
Mesh.RecombineNodeRepositioning = 1;  // reposition nodes after recombine
Mesh.Smoothing                  = 20; // Laplacian smoothing iterations
Mesh.RecombineAll               = 1;
Recombine Surface {1};

// --- Physical groups ---
Physical Curve("bottom", 1)          = {1};
Physical Curve("outflow", 2)         = {2};
Physical Curve("top", 3)             = {3};
Physical Curve("inflow", 4)          = {4};
Physical Curve("circle_boundary", 5) = {5};
Physical Surface("domain")           = {1};
