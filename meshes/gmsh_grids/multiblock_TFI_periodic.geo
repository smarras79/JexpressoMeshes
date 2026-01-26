// Two-block structured quad mesh in unit square
// 10 points per direction (11 nodes including boundaries)
SetFactory("OpenCASCADE");

// Mesh parameters
nelemx = 10;
nelemy = 10;
nelemz = 1;
xmin = -1;
xmax = 1;
ymin = -1;
ymax = 1;

//
// No more user-defined below this point:
//

n_x = Ceil(nelemx + 1)/2 + 1;  // Points per block in x-direction (including shared interface)
n_y = nelemy + 1;           // Points in y-direction
gridsize = (xmax - xmin)/nelemx;
xmid = (xmax + xmin)/2;

// Define points for Block 1 (left half: 0 to 0.5)
Point(1) = {xmin, ymin, 0, gridsize};
Point(2) = {xmid, ymin, 0, gridsize};
Point(3) = {xmid, ymax, 0, gridsize};
Point(4) = {xmin, ymax, 0, gridsize};

// Define points for Block 2 (right half: 0.5 to 1.0)
Point(5) = {xmax, ymin, 0, gridsize};
Point(6) = {xmax, ymax, 0, gridsize};

// Lines for Block 1
Line(1) = {1, 2};  // Bottom
Line(2) = {2, 3};  // Right (interface)
Line(3) = {3, 4};  // Top
Line(4) = {4, 1};  // Left

// Lines for Block 2
Line(5) = {2, 5};  // Bottom
Line(6) = {5, 6};  // Right
Line(7) = {6, 3};  // Top
// Line 2 is shared (interface)

// Curve loops and surfaces
Line Loop(1) = {1, 2, 3, 4};
Plane Surface(1) = {1};

Line Loop(2) = {5, 6, 7, -2};
Plane Surface(2) = {2};

// Set transfinite curves for structured mesh
Transfinite Line {1, 3}    = n_x Using Progression 1; // Horizontal lines in Block 1
Transfinite Line {5, 7}    = n_x Using Progression 1; // Horizontal lines in Block 2
Transfinite Line {2, 4, 6} = n_y Using Progression 1; // Vertical lines

// Make surfaces structured and recombine to quads
Transfinite Surface {1};
Transfinite Surface {2};
Recombine Surface {1};
Recombine Surface {2};

// Physical groups for boundaries (only CORNER boundary points, NOT interface points 2 and 3)
Physical Point("boundary",  1) = {1, 4, 5, 6};  // Only the 4 corners, NOT points 2 and 3!

Physical Curve("periodicy", 2) = {1, 5, 3, 7};
Physical Curve("periodicx", 3) = {6, 4};

// Physical group for domain - merging both blocks into one
Physical Surface("Domain", 4) = {1, 2};

// Note: Interface (Line 2) is NOT defined as a Physical Curve - it's internal
// Note: Points 2 and 3 (interface points) are NOT in Physical Point "boundary" - they're internal

// Mesh settings
//Mesh.ElementOrder = 1;
//Mesh.Algorithm = 6; // Frontal-Delaunay for quads

//+
Show "*";
