// -----------------------------------------------------------------------------
//
//  Gmsh GEO tutorial 10
//
//  Mesh size fields - XZ plane version with correct node ordering
//
// -----------------------------------------------------------------------------

// -----------------------------------------------------------------------------
// USER DEFINED QUANTITIES:
size_scaling = 100000;
xscaling = 5000;
yscaling = 1000;
zscaling = 10000;

ylevels = 2;

lc = 0.1*size_scaling;
xmin = -1*xscaling; xmax = 1*xscaling;
ymin = -1*yscaling; ymax = 1*yscaling;
zmin = 0; zmax = 1*zscaling;

xc = (xmin + xmax)/2;
yc = (ymin + ymax)/2;
zc = (zmin + zmax)/2;

//Refined box:
coarse_to_fine_ratio = 5;
refined_extension = 50000;
xbox_min = (xc - refined_extension); xbox_max = (xc + refined_extension);
zbox_min = (zc - refined_extension); zbox_max = (zc + refined_extension);

// END USER DEFINED
// -----------------------------------------------------------------------------

// Define points in XZ plane with Z varying first (standard for vertical coordinate)
Point(1) = {xmin, ymin, zmin, lc}; 
Point(2) = {xmin, ymin, zmax, lc}; // Z varies first
Point(3) = {xmax, ymin, zmax, lc}; // Then X varies
Point(4) = {xmax, ymin, zmin, lc};

// Lines connecting the points
Line(1) = {1,2}; // Vertical edge (Z direction)
Line(2) = {2,3}; // Top horizontal edge (X direction)
Line(3) = {3,4}; // Vertical edge (-Z direction)
Line(4) = {4,1}; // Bottom horizontal edge (-X direction)

Curve Loop(5) = {1,2,3,4};
Plane Surface(6) = {5};

Recombine Surface {6}; //TRI --> QUAD

Field[4] = Distance;
Field[4].PointsList = {1};

Field[6] = Box;
Field[6].VIn = lc / coarse_to_fine_ratio;
Field[6].VOut = lc;
Field[6].XMin = xbox_min;
Field[6].XMax = xbox_max;
Field[6].ZMin = zbox_min;
Field[6].ZMax = zbox_max;
Field[6].Thickness = 1*size_scaling;

Field[7] = Min;
Field[7].FieldsList = {2, 6};
Background Field = 7;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;

Mesh.Algorithm = 5;

// Extrude in Y direction
surfaceVector = Extrude {0, ymax - ymin, 0} {
  Surface{6};
  Layers{ylevels};
  Recombine;
};

//-------------------------------------------------------------------------------
//Boundary tagging
//-------------------------------------------------------------------------------
Physical Volume("internal", 1) = 1;
Physical Surface("left", 2)    = {27};
Physical Surface("right", 3)   = {19};
Physical Surface("front", 4)   = {6};    // Front face (y=ymin, in XZ plane)
Physical Surface("back", 5)    = {28};   // Back face (y=ymax, in XZ plane)
Physical Surface("bottom", 6)  = {15};   // Bottom face (z=zmin)
Physical Surface("top", 7)     = {23};   // Top face (z=zmax)

Show "*";
Show "*";