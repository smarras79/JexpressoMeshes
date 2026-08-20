// Coarse LESICP2 slab for laptop runs (4-8 MPI ranks).
// Same footprint as the old LESICP_coarse_test.msh (10240 x 1000 m), but
// with the TABLES 5000 m domain top instead of 3000 m.
//   20 x 3 x 16 elements -> 960 hexa
//   dx = 512 m, dy = 333.3 m, dz = 312.5 m
//   nop = 4 -> 81 x 13 x 65 = 68445 GLL points
// y is only 3 elements wide: this is a slab for exercising the case, not a
// resolved LES. The xy partitioner splits x (nx = nparts, ny = 1) at this
// aspect ratio, and 20 elements divide evenly over 4 ranks (5 each);
// 8 ranks give 3/3/3/3/2/2/2/2.
nelemx = 20;
nelemy = 3;
nelemz = 16;

xmin =  0;
xmax =	10240.0;
ymin =  0;
ymax =  1000.0;
zmin =   0;
zmax =  5000.0;
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

//Horizontal sides
Transfinite Line {1, 3} = npx;
//Vertical sides
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

    Physical Surface("periodicy") = {12,34};
    Physical Volume("internal") = {1};
    Physical Surface("top_wall") = {33};
    Physical Surface("MOST") = {25};
    Physical Surface("periodicx") = {21,29};
