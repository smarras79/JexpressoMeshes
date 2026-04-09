SetFactory("OpenCASCADE");

// 1. Setup constants
lc_domain = 0.1;
lc_letters = 0.02;

// 2. Create the outer square
Rectangle(1) = {-1, -1, 0, 2, 2};

// 3. Import the DXF (ensure it is in the same folder)
Merge "jexpresso.dxf";

// 4. Transform the letters to fit your [-1, 1] domain
// DXFs often export in large coordinates (like 100, 500)
// Use 'BoundingBox' to see the size, then Scale and Translate
// This example scales by 0.01 and moves to center
all_dxf_curves[] = {5:CombinedBoundary{Surface{:}}}; // Grabs imported curves
Dilate {{0, 0, 0}, 0.01} { Curve{all_dxf_curves[]}; }
Translate {-0.8, -0.1, 0} { Curve{all_dxf_curves[]}; }

// 5. THE MAGIC STEP: Create surfaces from the imported loops
// This tells Gmsh: "Find every closed loop of lines and make it a surface"
v[] = Curve Loop{:};
s[] = Surface{:};
ClassifySurfaces{s[]}; 

// 6. Boolean Subtraction
// We subtract the new letter surfaces from the main Rectangle (1)
// 'Delete' ensures the original solid letter surfaces are removed, leaving holes
BooleanFragments{ Surface{1}; Delete; }{ Surface{s[]}; Delete; }

// 7. Physical Groups
Physical Surface("domain") = {1};
Physical Curve("outer_boundary") = {1, 2, 3, 4};

// Grab everything that isn't the outer boundary for the letters
all_edges[] = Boundary{ Surface{1}; };
Physical Curve("j_espresso_boundary", 5) = {all_edges[]};
Recursive Delete Physical Curve("j_espresso_boundary", {1, 2, 3, 4});

// 8. Meshing Refinement (Distance Field)
Field[1] = Distance;
Field[1].CurvesList = {5};
Field[2] = Threshold;
Field[2].InField = 1;
Field[2].SizeMin = lc_letters;
Field[2].SizeMax = lc_domain;
Field[2].DistMin = 0.05;
Field[2].DistMax = 0.2;
Background Field = 2;

Recombine Surface {1};