nelemx = 16;
nelemy = 16;
nelemz = 19;
xmin =  0;
xmax =	3000;
ymin =  0;
ymax =  3000;
zmin =   0;
zmax =  1500;
gridsize = (xmax-xmin) / nelemx;

// User-defined minimum element size at walls (top and bottom surfaces)
min_dz = 10.0;  // minimum element height in meters at walls

// Calculate bump parameter to achieve desired minimum element size
// For Bump clustering: smallest elements at ends, largest in middle
domain_height = zmax - zmin;
avg_element_size = domain_height / nelemz;

// Calculate bump parameter based on desired minimum size
// Bump parameter controls the ratio between smallest and largest elements
// Smaller bump values create stronger clustering (smaller min elements)
target_ratio = min_dz / avg_element_size;
bump_param = (target_ratio > 0.1) ? target_ratio : 0.1;
bump_param = (bump_param > 1.0) ? 1.0 : bump_param;

Printf("Domain height: %g m", domain_height);
Printf("Average element size: %g m", avg_element_size);
Printf("Target minimum element size: %g m", min_dz);
Printf("Calculated bump parameter: %g", bump_param);
Printf("Estimated minimum element size at walls: %g m", avg_element_size * bump_param);

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
Transfinite Line {1, 3} = npx; //Ceil((xmax-xmin)/gridsize) Using Progression 1;
//Vertical sides - Wall clustering with constrained minimum size
Transfinite Curve {4, -2} = npz Using Bump bump_param;
Line Loop(11) = {4, 1, 2, 3};
Plane Surface(12) = {11};
Transfinite Surface {12};
Recombine Surface {12};
surfaceVector = Extrude {0,(ymax-ymin),0} {
  Surface{12};
  Layers{nelemy};
  Recombine;
};
//Coherence;
  /* surfaceVector contains in the following order:
     [0] - front surface (opposed to source surface)
     [1] - extruded volume
     [2] - bottom surface (belonging to 1st line in "Line Loop (6)")
     [3] - right surface (belonging to 2nd line in "Line Loop (6)")
     [4] - top surface (belonging to 3rd line in "Line Loop (6)")
     [5] - left surface (belonging to 4th line in "Light Loop (6)")
    */
    Physical Surface("periodicy") = {12,34};
    Physical Volume("internal") = {1};
    Physical Surface("top") = {33};
    Physical Surface("bottom") = {25};
    Physical Surface("periodicx") = {21,29};
    // from Plane Surface (6) ...
  //+
Show "*";
//+
Show "*";
//+
Show "*";
//+
Show "*";
//+
Show "*";