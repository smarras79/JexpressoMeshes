#!/usr/bin/env python3
"""
jexpresso_mesh.py
─────────────────────────────────────────────────────────────────────────────
Creates a 2-D quad mesh on the domain [-1,1]^2 with the word "JEXPRESSO"
cut out as empty (hollow) geometry.

Design
------
* Letter outlines come from matplotlib's TextPath (handles Bezier curves).
* Contour hierarchy is detected by containment depth:
    depth 0  ->  letter body  (tool for boolean cut)
    depth 1  ->  inner bowl of P / R / O  (separate domain surface, kept solid)
* Boolean cut: rectangle - letter bodies -> background domain
* Bowl surfaces are kept as separate OCC surfaces and added to the domain.
  The bowl boundary curves also belong to the "word" physical group.
* Pure-quad mesh via RecombineAll + SubdivisionAlgorithm=1.
  Even segment counts on every curve are enforced explicitly before the 2D pass.

Physical groups
---------------
  Curve  "bottom" / "right" / "top" / "left"  - outer box sides
  Curve  "word"                                - ALL letter boundary curves
  Surface "domain"                             - the meshed region

Requirements
------------
    pip install gmsh numpy matplotlib

Usage
-----
    python jexpresso_mesh.py          # writes jexpresso_domain.msh
    python jexpresso_mesh.py --gui    # same + opens GMSH GUI
"""

import sys
import gmsh
import numpy as np
from matplotlib.textpath import TextPath
from matplotlib.font_manager import FontProperties


# ---------------------------------------------------------------------------
# 1.  Geometry helpers
# ---------------------------------------------------------------------------

def point_in_poly(pt, poly):
    """Ray-casting point-in-polygon test."""
    x, y = pt
    n, inside, j = len(poly), False, len(poly) - 1
    for i in range(n):
        xi, yi = poly[i]; xj, yj = poly[j]
        if (yi > y) != (yj > y):
            if x < (xj - xi) * (y - yi) / (yj - yi) + xi:
                inside = not inside
        j = i
    return inside


def simplify(pts, tol=3e-3):
    """Remove successive near-duplicate points."""
    pts = np.array(pts, dtype=float)
    keep = [0]
    for i in range(1, len(pts)):
        if np.linalg.norm(pts[i] - pts[keep[-1]]) > tol:
            keep.append(i)
    if len(keep) > 1 and np.linalg.norm(pts[keep[-1]] - pts[keep[0]]) < tol:
        keep = keep[:-1]
    return pts[keep]


def get_text_polygons(text, size=1.0, font="DejaVu Sans", weight="bold"):
    """Return list of (N,2) arrays - one closed contour per matplotlib polygon."""
    fp = FontProperties(family=font, weight=weight)
    tp = TextPath((0, 0), text, size=size, prop=fp)
    out = []
    for p in tp.to_polygons():
        p = np.array(p, dtype=float)
        if len(p) > 1 and np.allclose(p[0], p[-1]):
            p = p[:-1]
        if len(p) >= 3:
            out.append(p)
    return out


def group_by_depth(polys):
    """
    Classify polygons by containment depth (font-winding-agnostic).

      depth 0  ->  letter outer body  (to be cut from the domain)
      depth 1  ->  inner bowl (P/R/O) (kept as a separate domain surface)

    Returns (outer_list, bowl_list).
    """
    n = len(polys)
    centroids = [p.mean(axis=0) for p in polys]
    depth = [0] * n
    for i in range(n):
        for j in range(n):
            if i != j and point_in_poly(centroids[i], polys[j]):
                depth[i] += 1
    outers = [polys[i] for i in range(n) if depth[i] == 0]
    bowls  = [polys[i] for i in range(n) if depth[i] == 1]
    return outers, bowls


# ---------------------------------------------------------------------------
# 2.  OCC geometry builders
# ---------------------------------------------------------------------------

class _Tags:
    pt  = 200
    crv = 3000
    cl  = 9000
    sf  = 10000

    @classmethod
    def new_pt(cls):
        t = cls.pt; cls.pt += 1; return t
    @classmethod
    def new_crv(cls):
        t = cls.crv; cls.crv += 1; return t
    @classmethod
    def new_cl(cls):
        t = cls.cl; cls.cl += 1; return t
    @classmethod
    def new_sf(cls):
        t = cls.sf; cls.sf += 1; return t


def poly_to_curve_loop(occ, pts):
    """Insert OCC points + lines for pts and return a CurveLoop tag."""
    pts = simplify(pts)
    n   = len(pts)
    if n < 3:
        return None
    pt_tags = []
    for x, y in pts:
        tag = _Tags.new_pt()
        occ.addPoint(float(x), float(y), 0.0, tag=tag)
        pt_tags.append(tag)
    ln_tags = []
    for i in range(n):
        tag = _Tags.new_crv()
        occ.addLine(pt_tags[i], pt_tags[(i + 1) % n], tag=tag)
        ln_tags.append(tag)
    cl = _Tags.new_cl()
    occ.addCurveLoop(ln_tags, tag=cl)
    return cl


def poly_to_surface(occ, pts):
    """Build a simple (single-loop, no holes) OCC plane surface."""
    cl = poly_to_curve_loop(occ, pts)
    if cl is None:
        return None
    sf = _Tags.new_sf()
    occ.addPlaneSurface([cl], tag=sf)
    return sf


# ---------------------------------------------------------------------------
# 3.  Main driver
# ---------------------------------------------------------------------------

def main(open_gui=False):

    # -- 3a.  Extract & scale letter outlines ---------------------------------
    #TEXT      = "JEXPRESSO"
    TEXT      = "ELEM LEARN"
    raw_polys = get_text_polygons(TEXT, size=1.0)
    if not raw_polys:
        raise RuntimeError("No polygons extracted - check font availability.")

    all_pts = np.vstack(raw_polys)
    xlo, ylo = all_pts.min(axis=0)
    xhi, yhi = all_pts.max(axis=0)

    TARGET_W, TARGET_H = 1.60, 0.36
    s  = min(TARGET_W / (xhi - xlo), TARGET_H / (yhi - ylo))
    cx = 0.5 * (xlo + xhi)
    cy = 0.5 * (ylo + yhi)

    scaled = [(p - np.array([cx, cy])) * s for p in raw_polys]
    outers, bowls = group_by_depth(scaled)

    print(f"  '{TEXT}'  ->  outer contours: {len(outers)},  "
          f"inner bowls (P/R/O): {len(bowls)}")

    # -- 3b.  Build OCC model -------------------------------------------------
    gmsh.initialize()
    gmsh.model.add("jexpresso_domain")
    occ = gmsh.model.occ

    # Background rectangle (tag=1)
    occ.addRectangle(-1.0, -1.0, 0.0, 2.0, 2.0, tag=1)

    # One simple surface per letter OUTER body
    outer_surfs = []
    for poly in outers:
        sf = poly_to_surface(occ, poly)
        if sf is not None:
            outer_surfs.append(sf)

    # One simple surface per inner BOWL (P/O/R) - stays as solid domain
    bowl_surfs = []
    for poly in bowls:
        sf = poly_to_surface(occ, poly)
        if sf is not None:
            bowl_surfs.append(sf)

    occ.synchronize()
    print(f"  Outer letter tags : {outer_surfs}")
    print(f"  Bowl surface tags : {bowl_surfs}")

    # -- 3c.  Boolean cut: rectangle - letter bodies --------------------------
    # Removes all letter areas (including bowl interiors) from the rectangle.
    # Bowls re-appear as the separate stand-alone surfaces built above.
    cut_result, _ = occ.cut(
        [(2, 1)],
        [(2, t) for t in outer_surfs],
        tag=-1, removeObject=True, removeTool=True
    )
    occ.synchronize()

    bg_surfs     = [s[1] for s in cut_result]
    domain_surfs = bg_surfs + bowl_surfs   # background + bowl islands
    print(f"  Background surfaces : {bg_surfs}")
    print(f"  Total domain surfaces: {domain_surfs}")

    # -- 3d.  Classify boundary curves into Physical Groups -------------------
    bnd = gmsh.model.getBoundary(
        [(2, s) for s in domain_surfs], oriented=False, combined=False
    )
    all_curves = sorted({abs(b[1]) for b in bnd})

    tol = 0.02
    bottom, right, top, left, word = [], [], [], [], []
    for ct in all_curves:
        x0, y0, _, x1, y1, _ = gmsh.model.getBoundingBox(1, ct)
        if   abs(y0 + 1) < tol and abs(y1 + 1) < tol: bottom.append(ct)
        elif abs(x0 - 1) < tol and abs(x1 - 1) < tol: right.append(ct)
        elif abs(y0 - 1) < tol and abs(y1 - 1) < tol: top.append(ct)
        elif abs(x0 + 1) < tol and abs(x1 + 1) < tol: left.append(ct)
        else:                                           word.append(ct)

    gmsh.model.addPhysicalGroup(1, bottom, tag=1, name="bottom")
    gmsh.model.addPhysicalGroup(1, right,  tag=2, name="right")
    gmsh.model.addPhysicalGroup(1, top,    tag=3, name="top")
    gmsh.model.addPhysicalGroup(1, left,   tag=4, name="left")
    gmsh.model.addPhysicalGroup(1, word,   tag=5, name="word")
    gmsh.model.addPhysicalGroup(2, domain_surfs, tag=1, name="domain")

    # -- 3e.  Mesh settings & generation - PURE QUADS -------------------------
    lc = 0.06
    gmsh.option.setNumber("Mesh.CharacteristicLengthMin", 0.010)
    gmsh.option.setNumber("Mesh.CharacteristicLengthMax", lc)
    gmsh.option.setNumber("Mesh.Algorithm",              8)   # Frontal-Delaunay quads
    gmsh.option.setNumber("Mesh.RecombinationAlgorithm", 3)   # Blossom full-quad
    gmsh.option.setNumber("Mesh.RecombineAll",           1)
    # SubdivisionAlgorithm=1: barycentric split of residual triangles -> 0 triangles
    # REQUIREMENT: every curve must have an even segment count.
    gmsh.option.setNumber("Mesh.SubdivisionAlgorithm",   1)
    gmsh.option.setNumber("Mesh.MinimumCurveNodes",      3)   # >= 2 segs per curve

    # Pass 1: build initial 1D mesh
    gmsh.model.mesh.generate(1)

    # Enforce even segment counts on every curve
    fixed = 0
    for _, ctag in gmsh.model.getEntities(1):
        _, elem_tags, _ = gmsh.model.mesh.getElements(1, ctag)
        n_segs = sum(len(t) for t in elem_tags)
        if n_segs % 2 != 0:
            gmsh.model.mesh.setTransfiniteCurve(ctag, n_segs + 2)
            fixed += 1
    if fixed:
        print(f"  Forced even segments on {fixed} curve(s); re-running 1D ...")
        gmsh.model.mesh.generate(1)

    # Pass 2: 2D mesh - recombine + barycentric subdivision -> pure quads
    gmsh.model.mesh.generate(2)
    gmsh.model.mesh.optimize("Laplace2D")

    # -- 3f.  Output ----------------------------------------------------------
    out = "jexpresso_domain.msh"
    gmsh.write(out)

    print(f"\nMesh written -> {out}")
    print(f"   bottom : {len(bottom)} curve(s)")
    print(f"   right  : {len(right)}  curve(s)")
    print(f"   top    : {len(top)}    curve(s)")
    print(f"   left   : {len(left)}   curve(s)")
    print(f"   word   : {len(word)}   curve(s)  <- all letter boundaries")

    if open_gui:
        gmsh.fltk.run()

    gmsh.finalize()


if __name__ == "__main__":
    main(open_gui="--gui" in sys.argv)
