// Structured 2D Gmsh geometry for a simple building CFD case.
// Coordinates are x-horizontal and y-vertical; y represents height.
SetFactory("Built-in");

// --------------------
// Dimensions, in meters
// --------------------
building_width  = 200.0;
building_height =  50.0;

// Domain extents. Adjust these clearances if your CFD setup needs a
// larger fetch or a lower/higher channel.
x_min = -800.0;
x_b0  = -building_width/2.0;
x_b1  =  building_width/2.0;
x_max =  800.0;

y_min = 0.0;
y_b   = building_height;
y_max = 450.0;

// Structured mesh divisions per block edge.
// Current count: 5*4 + 5*4 + (5 + 2 + 5)*5 = 100 quadrangles.
nx_left  = 10;
nx_bldg  = 4;
nx_right = 10;
ny_bldg  = 1;
ny_top   = 5;

// --------------------
// Block-structured x-y domain
// --------------------
Point(1)  = {x_min, y_min, 0.0, 1.0};
Point(2)  = {x_b0,  y_min, 0.0, 1.0};
Point(3)  = {x_b1,  y_min, 0.0, 1.0};
Point(4)  = {x_max, y_min, 0.0, 1.0};

Point(5)  = {x_min, y_b,   0.0, 1.0};
Point(6)  = {x_b0,  y_b,   0.0, 1.0};
Point(7)  = {x_b1,  y_b,   0.0, 1.0};
Point(8)  = {x_max, y_b,   0.0, 1.0};

Point(9)  = {x_min, y_max, 0.0, 1.0};
Point(10) = {x_b0,  y_max, 0.0, 1.0};
Point(11) = {x_b1,  y_max, 0.0, 1.0};
Point(12) = {x_max, y_max, 0.0, 1.0};

Line(1)  = {1, 2};
Line(2)  = {2, 6};
Line(3)  = {6, 5};
Line(4)  = {5, 1};

Line(5)  = {3, 4};
Line(6)  = {4, 8};
Line(7)  = {8, 7};
Line(8)  = {7, 3};

Line(9)  = {5, 6};
Line(10) = {6, 10};
Line(11) = {10, 9};
Line(12) = {9, 5};

Line(13) = {6, 7};
Line(14) = {7, 11};
Line(15) = {11, 10};
Line(16) = {10, 6};

Line(17) = {7, 8};
Line(18) = {8, 12};
Line(19) = {12, 11};
Line(20) = {11, 7};

Curve Loop(1) = {1, 2, 3, 4};       // lower-left fluid block
Curve Loop(2) = {5, 6, 7, 8};       // lower-right fluid block
Curve Loop(3) = {9, 10, 11, 12};    // upper-left fluid block
Curve Loop(4) = {13, 14, 15, 16};   // upper-center fluid block
Curve Loop(5) = {17, 18, 19, 20};   // upper-right fluid block

Plane Surface(1) = {1};
Plane Surface(2) = {2};
Plane Surface(3) = {3};
Plane Surface(4) = {4};
Plane Surface(5) = {5};

// --------------------
// Structured quad mesh
// --------------------
Transfinite Curve {1, 3, 9, 11} = nx_left + 1;
Transfinite Curve {13, 15}      = nx_bldg + 1;
Transfinite Curve {5, 7, 17, 19}= nx_right + 1;

Transfinite Curve {2, 4, 6, 8}  = ny_bldg + 1;
Transfinite Curve {10, 12, 14, 16, 18, 20} = ny_top + 1;

Transfinite Surface {1, 2, 3, 4, 5};
Recombine Surface {1, 2, 3, 4, 5};

// --------------------
// Physical groups
// --------------------
Physical Surface("FLUID") = {1, 2, 3, 4, 5};

Physical Curve("periodicx") = {4, 12, 6, 18};
Physical Curve("top") = {11, 15, 19};
Physical Curve("ground") = {1, 5};
Physical Curve("building") = {2, 13, 8};

Mesh.Algorithm = 8;
Mesh.RecombineAll = 1;
Mesh.ElementOrder = 1;
