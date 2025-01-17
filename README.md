# JexpressoMeshes

This repo contains a collection of gmsh *.geo and *.msh meshes often used in our benchmarks.
The meshes directory used to be part of the main Jexpresso repo but it was growing in size so that
we decided to remove it from the Jexpresso history and have it stand alone.

After cloning the JexpressoMeshes repo, follow the instructions below to use the meshes to with Jexpresso:

``cd Jexpresso``

``rsync -avz JexpressoMeshes/meshes .``
