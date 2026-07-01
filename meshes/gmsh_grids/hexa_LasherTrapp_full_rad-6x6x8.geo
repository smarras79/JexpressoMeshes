nelemx = 6;
nelemy = 6;
nelemz = 8;

xmin =    0;
xmax = 8100;
ymin =    0;
ymax = 8100;
zmin =    0;
zmax = 8100;
gridsize = (xmax-xmin) / nelemx;

Point(1) = {xmin, ymin, zmin, gridsize};
Point(2) = {xmax, ymin, zmin, gridsize};
Point(3) = {xmax, ymin, zmax, gridsize};
Point(4) = {xmin, ymin, zmax, gridsize};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

npx = nelemx + 1;
npy = nelemy + 1;
npz = nelemz + 1;

// Horizontal sides
Transfinite Line {1, 3} = npx;
// Vertical sides
Transfinite Line {4, -2} = npz Using Progression 1.0;

Line Loop(11) = {4, 1, 2, 3};
Plane Surface(12) = {11};

Transfinite Surface {12};
Recombine Surface {12};

surfaceVector = Extrude {0,(ymax-ymin),0} {
  Surface{12};
  Layers{nelemy};
  Recombine;
};

/*
  surfaceVector layout:
  [0] 34  - back face  (y=ymax, periodicy)
  [1]  1  - volume
  [2] 25  - bottom     (z=zmin)
  [3] 21  - right      (x=xmax, periodicx)
  [4] 33  - top        (z=zmax)
  [5] 29  - left       (x=xmin, periodicx)
*/
Physical Surface("periodicy") = {12, 34};
Physical Volume("internal")   = {1};
Physical Surface("bottom")    = {25};
Physical Surface("top")       = {33};
Physical Surface("periodicx") = {21, 29};

Show "*";
