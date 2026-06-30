nelemx = 6;
nelemy = 6;
xmin =  -3.1415926535897;
xmax =	 3.1415926535897;
ymin =  -3.1415926535897;
ymax =   3.1415926535897;
gridsize = (xmax-xmin) / nelemx;

Point(1) = {xmin, ymin, 0, gridsize};
Point(2) = {xmax, ymin, 0, gridsize};
Point(3) = {xmax, ymax, 0, gridsize};
Point(4) = {xmin, ymax, 0, gridsize};

Line(1) = {1, 2};
Line(2) = {2, 3};
Line(3) = {3, 4};
Line(4) = {4, 1};

npx = nelemx + 1;
npy = nelemy + 1;

//Horizontal sides (x-direction)
Transfinite Line {1, 3} = npx; //Using Progression 1;
//Vertical sides (y-direction)
Transfinite Line {4, -2} = npy Using Progression 1.0;

Line Loop(11) = {4, 1, 2, 3};
Plane Surface(12) = {11};
Transfinite Surface {12};
Recombine Surface {12};

  /* Line Loop (11) order:
     {4, 1, 2, 3}
     [4] - left   side (x = xmin)
     [1] - bottom side (y = ymin)
     [2] - right  side (x = xmax)
     [3] - top    side (y = ymax)
    */
    Physical Surface("internal") = {12};
    Physical Line("periodicx") = {2, 4};  // right + left  (x = xmax, xmin)
    Physical Line("periodicy") = {1, 3};  // bottom + top  (y = ymin, ymax)
  //+
Show "*";
