nelemx = 20;
nelemy = 20;
nelemz = 20;

xmin = -5000.0;
xmax =  5000.0;
ymin =     0.0;
ymax = 10000.0;
zmin =     0.0;
zmax = 10000.0;

// Characteristic length based on x-direction
lc = (xmax - xmin)/nelemx;

// Create base surface in XZ plane at y=ymin
Point(1) = {xmin, ymin, zmin, lc};
Point(2) = {xmax, ymin, zmin, lc};
Point(3) = {xmax, ymin, zmax, lc};
Point(4) = {xmin, ymin, zmax, lc};

// Lines for base surface
Line(1) = {1, 2};  // bottom (z=zmin)
Line(2) = {2, 3};  // right (x=xmax)
Line(3) = {3, 4};  // top (z=zmax)
Line(4) = {4, 1};  // left (x=xmin)

npx = nelemx + 1;
npy = nelemy + 1;
npz = nelemz + 1;

// Transfinite lines for structured boundaries
// Horizontal sides (in x-direction)
Transfinite Line {1, 3} = npx;
// Vertical sides (in z-direction)
Transfinite Line {4, -2} = npz;

// Create base surface - NO Transfinite Surface (allows unstructured interior)
Curve Loop(1) = {4, 1, 2, 3};
Plane Surface(1) = {1};
Recombine Surface{1};

// Extrude in Y direction with structured layers
surfaceVector = Extrude {0, (ymax-ymin), 0} {
  Surface{1};
  Layers{nelemy};
  Recombine;
};

/* surfaceVector contains in the following order:
   [0] - front surface (opposed to source surface, y=ymax)
   [1] - extruded volume
   [2] - bottom surface (from Line 1, z=zmin)
   [3] - right surface (from Line 2, x=xmax)
   [4] - top surface (from Line 3, z=zmax)
   [5] - left surface (from Line 4, x=xmin)
  */

//-------------------------------------------------------------------------------
// Boundary tagging
//-------------------------------------------------------------------------------
Physical Volume("internal") = {1};
Physical Surface("back") = {1};        // y=ymin (base surface)
Physical Surface("front") = {26};      // y=ymax (extruded front)
Physical Surface("bottom") = {13};     // z=zmin
Physical Surface("right") = {17};      // x=xmax
Physical Surface("top") = {21};        // z=zmax
Physical Surface("left") = {25};       // x=xmin
