nelemx = 96;
nelemy = 16;
nelemz = 10;
//
// Nelx = Lx/(nop*Dx)
//
xmin =     0.0;
xmax = 80000.0;
xsplit = xmax / 2.0; // x-coordinate of the sea/land boundary (adjust as needed)
ymin =     0.0;
ymax =  5000.0;
zmin =     0.0;
zmax =  2000.0;

gridsize = (xmax - xmin) / nelemx;

// Number of elements in each x-half (must sum to nelemx)
nelemx_left  = nelemx / 2; // 48  --> "sea"  side
nelemx_right = nelemx - nelemx_left; // 48  --> "land" side

npx_left  = nelemx_left  + 1;
npx_right = nelemx_right + 1;
npy = nelemy + 1;
npz = nelemz + 1;

// -----------------------------------------------------------------------
// Points on the xz seed plane (y = ymin)
//
//   6 -------- 5 -------- 4
//   |  left    |  right   |
//   |  (sea)   |  (land)  |
//   1 -------- 2 --------- 3
//
// -----------------------------------------------------------------------
Point(1) = {xmin,   ymin, zmin, gridsize};
Point(2) = {xsplit, ymin, zmin, gridsize}; // split point, bottom
Point(3) = {xmax,   ymin, zmin, gridsize};
Point(4) = {xmax,   ymin, zmax, gridsize};
Point(5) = {xsplit, ymin, zmax, gridsize}; // split point, top
Point(6) = {xmin,   ymin, zmax, gridsize};

// Left rectangle edges (xmin -> xsplit)
Line(1) = {1, 2}; // bottom-left  (z = zmin)  --> will become "sea" after extrusion
Line(2) = {2, 5}; // shared middle vertical (x = xsplit)
Line(3) = {5, 6}; // top-left     (z = zmax)
Line(4) = {6, 1}; // left wall    (x = xmin)

// Right rectangle edges (xsplit -> xmax)
//   Line(2) is shared, traversed as -2 for the right loop
Line(5) = {2, 3}; // bottom-right (z = zmin)  --> will become "land" after extrusion
Line(6) = {3, 4}; // right wall   (x = xmax)
Line(7) = {4, 5}; // top-right    (z = zmax)

// Transfinite line counts
Transfinite Line {1, 3}    = npx_left  Using Progression 1.0;
Transfinite Line {5, 7}    = npx_right Using Progression 1.0;
Transfinite Line {4, 2, 6} = npz       Using Progression 1.0;

// Left seed surface
Line Loop(11)     = {1, 2, 3, 4};
Plane Surface(12) = {11};
Transfinite Surface {12} = {1, 2, 5, 6};
Recombine Surface {12};

// Right seed surface
Line Loop(13)     = {5, 6, 7, -2};
Plane Surface(14) = {13};
Transfinite Surface {14} = {2, 3, 4, 5};
Recombine Surface {14};

// -----------------------------------------------------------------------
// Extrude both seed surfaces in the y-direction
// -----------------------------------------------------------------------
surfaceVectorLeft[] = Extrude {0, (ymax - ymin), 0} {
  Surface{12};
  Layers{nelemy};
  Recombine;
};
/* surfaceVectorLeft contains, in order:
   [0] - front-left  surface (y = ymax, periodicy back)
   [1] - left  volume
   [2] - bottom-left surface (from Line 1, z = zmin) --> "sea"
   [3] - mid interface surface (from Line 2, x = xsplit, interior)
   [4] - top-left    surface (from Line 3, z = zmax)
   [5] - left wall   surface (from Line 4, x = xmin,  periodicx)
*/

surfaceVectorRight[] = Extrude {0, (ymax - ymin), 0} {
  Surface{14};
  Layers{nelemy};
  Recombine;
};
/* surfaceVectorRight contains, in order:
   [0] - front-right surface (y = ymax, periodicy back)
   [1] - right volume
   [2] - bottom-right surface (from Line 5, z = zmin) --> "land"
   [3] - right wall   surface (from Line 6, x = xmax,  periodicx)
   [4] - top-right    surface (from Line 7, z = zmax)
   [5] - mid interface surface (from Line 2, x = xsplit) -- merged with [3]left by Coherence
*/

// Merge shared nodes/entities at the internal x = xsplit interface
Coherence;

// -----------------------------------------------------------------------
// Physical groups
// -----------------------------------------------------------------------
// y-periodic faces: seed planes (y=ymin) + extruded fronts (y=ymax)
Physical Surface("periodicy") = {12, 14,
                                 surfaceVectorLeft[0],
                                 surfaceVectorRight[0]};

// Full volume
Physical Volume("internal") = {surfaceVectorLeft[1],
                                surfaceVectorRight[1]};

// Top lid (z = zmax)
Physical Surface("top_wall") = {surfaceVectorLeft[4],
                                 surfaceVectorRight[4]};

// Bottom surface -- split into sea (left) and land (right)
Physical Surface("sea")  = {surfaceVectorLeft[2]};
Physical Surface("land") = {surfaceVectorRight[2]};

// x-periodic faces: left wall (x=xmin) and right wall (x=xmax)
Physical Surface("periodicx") = {surfaceVectorLeft[5],
                                  surfaceVectorRight[3]};

Show "*";
