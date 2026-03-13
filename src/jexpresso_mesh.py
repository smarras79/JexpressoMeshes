#!/usr/bin/env python3
"""
jexpresso_mesh.py

How to run it:

python3.11 jexpresso_mesh.py          # produces jexpresso_domain.msh
python3.11 jexpresso_mesh.py --gui    # same + opens GMSH viewer


---------------------------------------------------------------------------
2-D pure-quad mesh on [-1,1]^2 with text cut out as hollow geometry.

Each letter gets its OWN Physical Curve tag, e.g. "J", "E1", "X", "P",
"R", "E2", "S1", "S2", "O" -- allowing per-letter boundary conditions.
Letters with inner bowls (P, R, O) have their bowl curves included in the
same tag as their outer stroke.

Physical groups
---------------
  Curve  "bottom" / "right" / "top" / "left"  - outer box edges
  Curve  "<LETTER>"  or  "<LETTER>_N"          - per-letter boundary curves
  Surface "domain"                             - the meshed region

Requirements:  pip install gmsh numpy matplotlib
Usage:
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
    """Remove successive near-duplicate vertices."""
    pts = np.asarray(pts, dtype=float)
    keep = [0]
    for i in range(1, len(pts)):
        if np.linalg.norm(pts[i] - pts[keep[-1]]) > tol:
            keep.append(i)
    if len(keep) > 1 and np.linalg.norm(pts[keep[-1]] - pts[keep[0]]) < tol:
        keep = keep[:-1]
    return pts[keep]


def get_text_polygons(text, size=1.0, font="DejaVu Sans", weight="bold"):
    """Return list of (N,2) arrays, one closed contour per glyph contour."""
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
    Classify by containment depth (font-winding-agnostic).
      depth 0  ->  letter outer body
      depth 1  ->  inner bowl/counter of P, R, O
    Returns (outer_list, bowl_list).
    """
    n         = len(polys)
    centroids = [p.mean(axis=0) for p in polys]
    depth     = [0] * n
    for i in range(n):
        for j in range(n):
            if i != j and point_in_poly(centroids[i], polys[j]):
                depth[i] += 1
    outers = [polys[i] for i in range(n) if depth[i] == 0]
    bowls  = [polys[i] for i in range(n) if depth[i] == 1]
    return outers, bowls


def make_letter_labels(text):
    """
    Return a label list matching the non-space characters of *text*,
    disambiguating repeated letters with _1, _2, ...

    E.g. "JEXPRESSO" -> ["J","E1","X","R","E2","S1","S2"]
         "ELEM LEARN"-> ["E1","L1","E2","M","L2","E3","A","R","N"]
    """
    chars = [c for c in text if c != ' ']
    count = {}
    total = {}
    for c in chars:
        total[c] = total.get(c, 0) + 1
    labels = []
    for c in chars:
        count[c] = count.get(c, 0) + 1
        if total[c] > 1:
            labels.append(f"{c}_{count[c]}")
        else:
            labels.append(c)
    return labels


def poly_bbox(poly):
    """Return (xmin, ymin, xmax, ymax) of a polygon."""
    return poly[:,0].min(), poly[:,1].min(), poly[:,0].max(), poly[:,1].max()


def curve_center(ctag):
    """Return the midpoint of a curve's bounding box."""
    x0, y0, _, x1, y1, _ = gmsh.model.getBoundingBox(1, ctag)
    return 0.5*(x0+x1), 0.5*(y0+y1)


def assign_curve_to_letter(ctag, letter_bboxes, margin=0.01):
    """
    Return the index into letter_bboxes whose bbox (expanded by margin)
    contains the curve's centre.  Falls back to nearest-centroid if none match.
    """
    cx, cy = curve_center(ctag)
    # First: strict containment test
    for i, (xlo, ylo, xhi, yhi) in enumerate(letter_bboxes):
        if (xlo - margin) <= cx <= (xhi + margin) and \
           (ylo - margin) <= cy <= (yhi + margin):
            return i
    # Fallback: nearest bounding-box centroid
    best, best_d = 0, float('inf')
    for i, (xlo, ylo, xhi, yhi) in enumerate(letter_bboxes):
        d = (cx - 0.5*(xlo+xhi))**2 + (cy - 0.5*(ylo+yhi))**2
        if d < best_d:
            best, best_d = i, d
    return best


# ---------------------------------------------------------------------------
# 2.  OCC geometry builders
# ---------------------------------------------------------------------------

class _Tags:
    pt  = 200
    crv = 3000
    cl  = 9000
    sf  = 10000

    @classmethod
    def new_pt(cls):  t = cls.pt;  cls.pt  += 1; return t
    @classmethod
    def new_crv(cls): t = cls.crv; cls.crv += 1; return t
    @classmethod
    def new_cl(cls):  t = cls.cl;  cls.cl  += 1; return t
    @classmethod
    def new_sf(cls):  t = cls.sf;  cls.sf  += 1; return t


def poly_to_curve_loop(occ, pts):
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
#    TEXT      = "JEXRESS" #JEXPRESSO
    TEXT      = "JEX-EL"
    raw_polys = get_text_polygons(TEXT, size=1.0)
    if not raw_polys:
        raise RuntimeError("No polygons extracted -- check font availability.")

    all_pts  = np.vstack(raw_polys)
    xlo, ylo = all_pts.min(axis=0)
    xhi, yhi = all_pts.max(axis=0)

    TARGET_W, TARGET_H = 1.60, 0.36
    s  = min(TARGET_W / (xhi - xlo), TARGET_H / (yhi - ylo))
    cx = 0.5 * (xlo + xhi)
    cy = 0.5 * (ylo + yhi)

    scaled        = [(p - np.array([cx, cy])) * s for p in raw_polys]
    outers, bowls = group_by_depth(scaled)

    # Sort outer contours left-to-right (reading order)
    outers.sort(key=lambda p: p[:,0].mean())

    # Build per-letter labels  ["J","E_1","X","P","R","E_2","S_1","S_2","O"]
    labels       = make_letter_labels(TEXT)
    letter_bboxes = [poly_bbox(o) for o in outers]

    print(f"  '{TEXT}'  ->  outer contours: {len(outers)}, "
          f"inner bowls (P/R/O): {len(bowls)}")
    print(f"  Letter labels: {labels}")

    # -- 3b.  Build OCC model -------------------------------------------------
    gmsh.initialize()
    gmsh.model.add("jexpresso_domain")
    occ = gmsh.model.occ

    # Background rectangle (tag=1)
    occ.addRectangle(-1.0, -1.0, 0.0, 2.0, 2.0, tag=1)

    outer_surfs = []
    for poly in outers:
        sf = poly_to_surface(occ, poly)
        if sf is not None:
            outer_surfs.append(sf)

    bowl_surfs = []
    for poly in bowls:
        sf = poly_to_surface(occ, poly)
        if sf is not None:
            bowl_surfs.append(sf)

    occ.synchronize()
    print(f"  Outer letter tags : {outer_surfs}")
    print(f"  Bowl surface tags : {bowl_surfs}")

    # -- 3c.  Boolean cut: rectangle - letter bodies --------------------------
    cut_result, _ = occ.cut(
        [(2, 1)],
        [(2, t) for t in outer_surfs],
        tag=-1, removeObject=True, removeTool=True
    )
    occ.synchronize()

    bg_surfs     = [s[1] for s in cut_result]
    domain_surfs = bg_surfs + bowl_surfs
    print(f"  Background surfaces  : {bg_surfs}")
    print(f"  Total domain surfaces: {domain_surfs}")

    # -- 3d.  Classify boundary curves ----------------------------------------
    bnd = gmsh.model.getBoundary(
        [(2, s) for s in domain_surfs], oriented=False, combined=False
    )
    all_curves = sorted({abs(b[1]) for b in bnd})

    tol = 0.02
    bottom, right, top, left = [], [], [], []
    word_curves = []           # all letter-boundary curves

    for ct in all_curves:
        x0, y0, _, x1, y1, _ = gmsh.model.getBoundingBox(1, ct)
        if   abs(y0 + 1) < tol and abs(y1 + 1) < tol: bottom.append(ct)
        elif abs(x0 - 1) < tol and abs(x1 - 1) < tol: right.append(ct)
        elif abs(y0 - 1) < tol and abs(y1 - 1) < tol: top.append(ct)
        elif abs(x0 + 1) < tol and abs(x1 + 1) < tol: left.append(ct)
        else:                                           word_curves.append(ct)

    # Assign each word-boundary curve to the correct letter by bounding-box
    # containment of the curve's centre.
    per_letter = {label: [] for label in labels}
    for ct in word_curves:
        idx   = assign_curve_to_letter(ct, letter_bboxes)
        label = labels[idx]
        per_letter[label].append(ct)

    # -- 3e.  Physical groups -------------------------------------------------
    gmsh.model.addPhysicalGroup(1, bottom, tag=1, name="bottom")
    gmsh.model.addPhysicalGroup(1, right,  tag=2, name="right")
    gmsh.model.addPhysicalGroup(1, top,    tag=3, name="top")
    gmsh.model.addPhysicalGroup(1, left,   tag=4, name="left")

    # One Physical Curve per letter, tags starting at 10
    letter_tag_start = 10
    for i, label in enumerate(labels):
        curves = per_letter.get(label, [])
        if curves:
            gmsh.model.addPhysicalGroup(1, curves,
                                        tag=letter_tag_start + i,
                                        name=label)
            print(f"  Physical Curve '{label}' (tag {letter_tag_start+i}): "
                  f"{len(curves)} curve(s)")

    gmsh.model.addPhysicalGroup(2, domain_surfs, tag=1, name="domain")

    # -- 3f.  Pure-quad mesh --------------------------------------------------
    lc = 0.06
    gmsh.option.setNumber("Mesh.CharacteristicLengthMin", 0.010)
    gmsh.option.setNumber("Mesh.CharacteristicLengthMax", lc)
    gmsh.option.setNumber("Mesh.Algorithm",              8)  # Frontal-Del quads
    gmsh.option.setNumber("Mesh.RecombinationAlgorithm", 3)  # Blossom full-quad
    gmsh.option.setNumber("Mesh.RecombineAll",           1)
    gmsh.option.setNumber("Mesh.SubdivisionAlgorithm",   1)  # guarantees 0 triangles
    gmsh.option.setNumber("Mesh.MinimumCurveNodes",      3)

    gmsh.model.mesh.generate(1)

    # Enforce even segment counts (required by SubdivisionAlgorithm=1)
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

    gmsh.model.mesh.generate(2)
    gmsh.model.mesh.optimize("Laplace2D")

    # -- 3g.  Output ----------------------------------------------------------
    out = "jexpresso_domain.msh"
    gmsh.write(out)

    print(f"\nMesh written -> {out}")
    print(f"   bottom : {len(bottom)} curve(s)")
    print(f"   right  : {len(right)}  curve(s)")
    print(f"   top    : {len(top)}    curve(s)")
    print(f"   left   : {len(left)}   curve(s)")
    for label in labels:
        n = len(per_letter.get(label, []))
        print(f"   {label:<6} : {n} curve(s)")

    if open_gui:
        gmsh.fltk.run()

    gmsh.finalize()


if __name__ == "__main__":
    main(open_gui="--gui" in sys.argv)
