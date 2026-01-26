// -----------------------------------------------------------------------------
//
//  Gmsh GEO tutorial 10
//
//  Mesh size fields
//
// -----------------------------------------------------------------------------

// In addition to specifying target mesh sizes at the points of the geometry
// (see `t1.geo') or using a background mesh (see `t7.geo'), you can use general
// mesh size "Fields".

// -----------------------------------------------------------------------------
// USER DEFINED QUANTITIES:
size_scaling = 100000;
xscaling = 5000;
yscaling = 1000;
zscaling = 10000;

ylevels = 2;  // Changed from zlevels to ylevels since we're extruding in Y now

lc = 0.1*size_scaling;
xmin = -1*xscaling; xmax = 1*xscaling;
ymin = -1*yscaling; ymax = 1*yscaling;
zmin = 0; zmax = 1*zscaling;

xc = (xmin + xmax)/2;
yc = (ymin + ymax)/2;
zc = (zmin + zmax)/2;  // Updated to be center of z-range

//Refined box:
coarse_to_fine_ratio = 10; //--> how many times finer is the refined mesh w.r.t. coarsest mesh size
refined_extension = 50000;
xbox_min = (xc - refined_extension); xbox_max = (xc + refined_extension);
zbox_min = (zc - refined_extension); zbox_max = (zc + refined_extension);  // Changed from ybox to zbox


// END USER DEFINED
// -----------------------------------------------------------------------------

// Define points in XZ plane (at y=ymin)
Point(1) = {xmin, ymin, zmin, lc}; 
Point(2) = {xmax, ymin, zmin, lc};
Point(3) = {xmax, ymin, zmax, lc};  // Changed: z=zmax instead of y=ymax
Point(4) = {xmin, ymin, zmax, lc};  // Changed: z=zmax instead of y=ymax

Line(1) = {1,2}; Line(2) = {2,3}; Line(3) = {3,4}; Line(4) = {4,1};

Curve Loop(5) = {1,2,3,4};
Plane Surface(6) = {5};

Recombine Surface {6}; //TRI --> QUAD

// Updated Box field to work in XZ plane
Field[4] = Distance;
Field[4].PointsList = {1};

Field[6] = Box;
Field[6].VIn = lc / coarse_to_fine_ratio;
Field[6].VOut = lc;
Field[6].XMin = xbox_min;
Field[6].XMax = xbox_max;
Field[6].ZMin = zbox_min;  // Changed from YMin
Field[6].ZMax = zbox_max;  // Changed from YMax
Field[6].Thickness = 1*size_scaling; //larger value --> more extended refined region

// Let's use the minimum of all the fields as the background mesh size field
Field[7] = Min;
Field[7].FieldsList = {2, 6};
Background Field = 7;

Mesh.MeshSizeExtendFromBoundary = 0;
Mesh.MeshSizeFromPoints = 0;
Mesh.MeshSizeFromCurvature = 0;

Mesh.Algorithm = 5;

// Extrude in Y direction instead of Z
surfaceVector = Extrude {0, ymax - ymin, 0} {  // Changed from {0, 0, zmax}
  Surface{6};
  Layers{ylevels};  // Changed from zlevels
  Recombine;
};

//-------------------------------------------------------------------------------
//Boundary tagging
//-------------------------------------------------------------------------------
Physical Volume("internal", 1) = 1;
Physical Surface("left", 2)    = {27};
Physical Surface("right", 3)   = {19};
Physical Surface("bottom", 4)  = {6};   // This is now the front face (y=ymin)
Physical Surface("top", 5)     = {28};  // This is now the back face (y=ymax)
Physical Surface("front", 6)   = {15};  // This is now the bottom face (z=zmin)
Physical Surface("back", 7)    = {23};  // This is now the top face (z=zmax)

Show "*";
Show "*";