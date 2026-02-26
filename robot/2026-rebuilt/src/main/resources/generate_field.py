#!/usr/bin/env python3
"""
Generate a simplified collision OBJ for the 2026 REBUILT FRC field.
All units in meters. Origin at blue-alliance / left-guardrail corner.
X+ toward red alliance, Y+ across field, Z+ up

Each geometry element is stored as:
  {"name": str, "verts": [(x,y,z), ...], "faces": [[i, ...], ...]}
  where face indices are 0-based within the element's vertex list.
"""

import math
import os

# --- Field constants (converted from inches to meters) ---
FIELD_LENGTH = 16.540       # 651.2in
FIELD_WIDTH  = 8.070        # 317.7in
GUARDRAIL_HEIGHT = 0.510    # ~20in guardrail height (long sides)
ALLIANCE_WALL_HEIGHT = 2.00 # taller walls at driver station ends
WALL_THICK   = 0.050        # collision wall thickness

# HUB: 47in x 47in rectangular box with hex funnel on top
HUB_SIZE       = 1.194   # 47in base footprint
HUB_DIST       = 4.034   # 158.84in from alliance wall to HUB center
HUB_BOX_TOP    = 1.200   # estimated height of the rectangular box portion
HUB_OPENING_Z  = 1.830   # 72in - front edge of hex opening (top of funnel)
HUB_TOP_HEX_CR = 0.612   # circumradius of top hex (41.7in flat-to-flat)
HUB_BOT_HEX_CR = 0.300   # circumradius of bottom hex (estimated, ~0.52m F-F)
HUB_WALL_THICK = 0.050
HUB_EXIT_BOTTOM = 0.500  # bottom of ball exit slit (~halfway up hub)
HUB_EXIT_TOP    = 0.700  # top of ball exit slit (~0.2m tall opening)
HUB_BACKBOARD_TOP = 3.000 # backboard extends well above the funnel
HUB_RAMP_HIGH_Z = 0.800  # interior ramp back edge (alliance side, high)
HUB_RAMP_LOW_Z  = 0.500  # interior ramp front edge (meets exit slit bottom)

# Bump: 73in W x 44.4in D x 6.513in H, 15-degree ramps
BUMP_W = 1.854  # width (Y)
BUMP_D = 1.124  # depth (X) - 44.25in
BUMP_H = 0.165  # height (Z) - 6.513in

# Trench: thin overhead beam (~2x4 cross-section)
TRENCH_CLEARANCE = 0.565  # 22.25in passable height underneath
TRENCH_BEAM_Z = 0.089     # beam height (3.5in, like a 2x4 on edge)
TRENCH_BEAM_X = 0.100     # beam depth in X direction
TRENCH_PASS_W  = 1.285    # 50.59in passable width underneath
TRENCH_WALL_W  = 0.305    # 12in wall between trench and bump
TRENCH_TOTAL_W = TRENCH_PASS_W + TRENCH_WALL_W  # 62.59in total trench width
TRENCH_H       = 1.022    # 40.25in total trench structure height

# Depot: 42in W x 27in D, barrier ~1.125in tall
DEPOT_W = 1.070   # 42in
DEPOT_D = 0.686   # 27in
DEPOT_H = 0.029   # ~1.125in

# Tower: 49.25in W x 45in D x 78.25in H
TOWER_BASE_W = 0.991   # 39in
TOWER_BASE_D = 1.148   # 45.18in
TOWER_BASE_H = 0.008   # ~0.3in edge height
UPRIGHT_THICK = 0.038   # 1.5in (Y dimension)
UPRIGHT_DEPTH = 0.089   # 3.5in (X dimension)
UPRIGHT_H     = 1.831   # 72.1in
UPRIGHT_SPACING = 0.819 # 32.25in between uprights
RUNG_OD   = 0.042  # 1.66in OD
RUNG_OVERHANG = 0.149  # 5.875in past outer face of upright
LOW_RUNG_Z  = 0.686   # 27in
MID_RUNG_Z  = 1.143   # 45in
HIGH_RUNG_Z = 1.600   # 63in

# --- Derived positions ---
CY = FIELD_WIDTH / 2  # field center Y = 4.035

hub_half = HUB_SIZE / 2  # 0.597
BLUE_HUB_CX = HUB_DIST + hub_half  # 158.6in to near face + half hub = 4.625

bump_left_y1  = CY - hub_half - BUMP_W
bump_left_y2  = CY - hub_half
bump_right_y1 = CY + hub_half
bump_right_y2 = CY + hub_half + BUMP_W

bump_half_d = BUMP_D / 2

TOWER_OFFSET = 0.289  # 11.38in from field midline
TOWER_CY = CY - TOWER_OFFSET  # blue tower offset toward left guardrail
upright_left_cy  = TOWER_CY - UPRIGHT_SPACING / 2
upright_right_cy = TOWER_CY + UPRIGHT_SPACING / 2
UPRIGHT_CX_OFFSET = 1.000

rung_y1 = upright_left_cy - UPRIGHT_THICK/2 - RUNG_OVERHANG
rung_y2 = upright_right_cy + UPRIGHT_THICK/2 + RUNG_OVERHANG

DEPOT_OFFSET_FROM_MID = 1.929  # 75.93in from field midline to depot center
BLUE_DEPOT_Y1 = CY + DEPOT_OFFSET_FROM_MID - DEPOT_W / 2
BLUE_DEPOT_Y2 = CY + DEPOT_OFFSET_FROM_MID + DEPOT_W / 2


# ============================================================
# Geometry helpers
# ============================================================

def make_box(name, x1, y1, z1, x2, y2, z2):
    """Axis-aligned box with outward-facing CCW quads."""
    x1, x2 = min(x1, x2), max(x1, x2)
    y1, y2 = min(y1, y2), max(y1, y2)
    z1, z2 = min(z1, z2), max(z1, z2)
    verts = [
        (x1, y1, z1), (x2, y1, z1), (x2, y2, z1), (x1, y2, z1),  # 0-3 bottom
        (x1, y1, z2), (x2, y1, z2), (x2, y2, z2), (x1, y2, z2),  # 4-7 top
    ]
    faces = [
        [3, 2, 1, 0],  # bottom (-Z)
        [4, 5, 6, 7],  # top (+Z)
        [0, 1, 5, 4],  # front (-Y)
        [2, 3, 7, 6],  # back (+Y)
        [0, 4, 7, 3],  # left (-X)
        [1, 2, 6, 5],  # right (+X)
    ]
    return {"name": name, "verts": verts, "faces": faces}


def make_bump(name, x1, x2, y1, y2, peak_z):
    """Triangular prism: ridge along Y, two ramp faces.

    IMPORTANT: Ramp faces MUST be pre-triangulated here, not left as quads.

    When the OBJ is loaded by JavaGL (ObjUtils.convertToRenderable), quads are
    fan-triangulated from the first vertex. For a quad like [1, 4, 3, 0] this
    produces triangles (1,4,3) and (1,3,0). Although the surface normals are
    mathematically identical to splitting from vertex 0 — (0,1,4) and (0,4,3) —
    ODE4J's trimesh-box collision behaves differently: the fan-from-v1 winding
    causes the robot chassis to slide through the ramp instead of climbing it.

    The working winding splits each ramp quad from a BASE vertex (v0 or v2),
    not the RIDGE vertex (v1 or v4). This is verified in BumpTraversalTest.
    """
    x_mid = (x1 + x2) / 2
    verts = [
        (x1,    y1, 0),       # 0  base, near, -X side
        (x_mid, y1, peak_z),  # 1  ridge, near
        (x2,    y1, 0),       # 2  base, near, +X side
        (x1,    y2, 0),       # 3  base, far, -X side
        (x_mid, y2, peak_z),  # 4  ridge, far
        (x2,    y2, 0),       # 5  base, far, +X side
    ]
    faces = [
        [0, 2, 1],              # near end cap
        [3, 4, 5],              # far end cap
        [0, 3, 5],  [0, 5, 2],  # bottom (quad → 2 tris)
        [0, 1, 4],  [0, 4, 3],  # left ramp  — split from base vertex 0
        [2, 5, 4],  [2, 4, 1],  # right ramp — split from base vertex 2
    ]
    return {"name": name, "verts": verts, "faces": faces}


def make_hex_funnel(name, cx, cy, bot_cr, top_cr, bot_z, top_z):
    """Hex frustum funnel: wider at top (opening), narrower at bottom.
    6 bottom verts + 6 top verts, 6 quad side faces.
    Vertex 0 at angle=0 (+X direction).
    """
    verts = []
    for i in range(6):
        a = math.radians(i * 60)
        verts.append((cx + bot_cr * math.cos(a), cy + bot_cr * math.sin(a), bot_z))
    for i in range(6):
        a = math.radians(i * 60)
        verts.append((cx + top_cr * math.cos(a), cy + top_cr * math.sin(a), top_z))

    faces = []
    for i in range(6):
        b0, b1 = i, (i + 1) % 6
        t0, t1 = i + 6, (i + 1) % 6 + 6
        faces.append([b0, b1, t1, t0])
    return {"name": name, "verts": verts, "faces": faces}


def make_hub_ramp(name, hx1, hx2, hy1, hy2, t, high_z, low_z):
    """Interior ramp: slopes from alliance side (hx1, high) toward neutral zone (hx2, low)."""
    verts = [
        (hx1 + t, hy1 + t, high_z),  # 0 back-left
        (hx2 - t, hy1 + t, low_z),   # 1 front-left
        (hx2 - t, hy2 - t, low_z),   # 2 front-right
        (hx1 + t, hy2 - t, high_z),  # 3 back-right
    ]
    faces = [[0, 1, 2, 3]]  # upward-facing
    return {"name": name, "verts": verts, "faces": faces}


def make_triangle(name, v0, v1, v2):
    """Single triangular face."""
    return {"name": name, "verts": [v0, v1, v2], "faces": [[0, 1, 2]]}


def mirror_element(name, elem):
    """Mirror via 180-degree rotation about field center (flip X and Y, keep Z)."""
    new_verts = [
        (FIELD_LENGTH - x, FIELD_WIDTH - y, z)
        for (x, y, z) in elem["verts"]
    ]
    new_faces = [list(reversed(f)) for f in elem["faces"]]
    return {"name": name, "verts": new_verts, "faces": new_faces}


# ============================================================
# Build list of all collision elements
# ============================================================
elements = []

# --- 4 Field Walls ---
elements.append(make_box("blue_alliance_wall",
    -WALL_THICK, -WALL_THICK, 0, 0, FIELD_WIDTH+WALL_THICK, ALLIANCE_WALL_HEIGHT))
elements.append(make_box("red_alliance_wall",
    FIELD_LENGTH, -WALL_THICK, 0, FIELD_LENGTH+WALL_THICK, FIELD_WIDTH+WALL_THICK, ALLIANCE_WALL_HEIGHT))
elements.append(make_box("left_guardrail",
    0, -WALL_THICK, 0, FIELD_LENGTH, 0, GUARDRAIL_HEIGHT))
elements.append(make_box("right_guardrail",
    0, FIELD_WIDTH, 0, FIELD_LENGTH, FIELD_WIDTH+WALL_THICK, GUARDRAIL_HEIGHT))

# --- 4 Bumps ---
bx1 = BLUE_HUB_CX - bump_half_d
bx2 = BLUE_HUB_CX + bump_half_d
b_bump_l = make_bump("blue_bump_left",  bx1, bx2, bump_left_y1,  bump_left_y2,  BUMP_H)
b_bump_r = make_bump("blue_bump_right", bx1, bx2, bump_right_y1, bump_right_y2, BUMP_H)
elements.append(b_bump_l)
elements.append(b_bump_r)
elements.append(mirror_element("red_bump_left",  b_bump_r))
elements.append(mirror_element("red_bump_right", b_bump_l))

# --- 4 Trench overhead beams (thin 2x4-ish cross section) ---
beam_x1 = BLUE_HUB_CX - TRENCH_BEAM_X / 2
beam_x2 = BLUE_HUB_CX + TRENCH_BEAM_X / 2
beam_z1 = TRENCH_CLEARANCE
beam_z2 = TRENCH_CLEARANCE + TRENCH_BEAM_Z

b_tr_l = make_box("blue_trench_left",  beam_x1, 0,             beam_z1, beam_x2, bump_left_y1,  beam_z2)
b_tr_r = make_box("blue_trench_right", beam_x1, bump_right_y2, beam_z1, beam_x2, FIELD_WIDTH,   beam_z2)
elements.append(b_tr_l)
elements.append(b_tr_r)
elements.append(mirror_element("red_trench_left",  b_tr_r))
elements.append(mirror_element("red_trench_right", b_tr_l))

# --- 4 Trench-to-bump walls (solid wall between passable trench opening and bump) ---
b_tw_l = make_box("blue_trench_wall_left",
    bx1, bump_left_y1 - TRENCH_WALL_W, 0, bx2, bump_left_y1, TRENCH_H)
b_tw_r = make_box("blue_trench_wall_right",
    bx1, bump_right_y2, 0, bx2, bump_right_y2 + TRENCH_WALL_W, TRENCH_H)
elements.append(b_tw_l)
elements.append(b_tw_r)
elements.append(mirror_element("red_trench_wall_left",  b_tw_r))
elements.append(mirror_element("red_trench_wall_right", b_tw_l))

# --- 2 HUBs (walls + hex funnel + backboard + side panels + ramp) ---
hx1 = BLUE_HUB_CX - hub_half   # alliance side for blue
hx2 = BLUE_HUB_CX + hub_half   # neutral zone side for blue
hy1 = CY - hub_half
hy2 = CY + hub_half
t = HUB_WALL_THICK

# 5 walls: alliance side solid, neutral side split into lower + upper with slit between
b_hub_alliance     = make_box("blue_hub_alliance_wall",     hx1, hy1, 0, hx1+t, hy2, HUB_BOX_TOP)
b_hub_neutral_low  = make_box("blue_hub_neutral_wall_low",  hx2-t, hy1, 0, hx2, hy2, HUB_EXIT_BOTTOM)
b_hub_neutral_high = make_box("blue_hub_neutral_wall_high", hx2-t, hy1, HUB_EXIT_TOP, hx2, hy2, HUB_BOX_TOP)
b_hub_left         = make_box("blue_hub_left_wall",         hx1, hy1, 0, hx2, hy1+t, HUB_BOX_TOP)
b_hub_right        = make_box("blue_hub_right_wall",        hx1, hy2-t, 0, hx2, hy2, HUB_BOX_TOP)

# Hex funnel on top: narrow at bottom (box top), wide at top (opening)
b_hub_funnel = make_hex_funnel("blue_hub_funnel",
    BLUE_HUB_CX, CY, HUB_BOT_HEX_CR, HUB_TOP_HEX_CR, HUB_BOX_TOP, HUB_OPENING_Z)

# Interior ramp: alliance side high, neutral zone side low (toward exits)
b_hub_ramp = make_hub_ramp("blue_hub_ramp",
    hx1, hx2, hy1, hy2, t, HUB_RAMP_HIGH_Z, HUB_RAMP_LOW_Z)

# Backboard on NEUTRAL ZONE side (+X for blue), extends well above funnel
b_hub_backboard = make_box("blue_hub_backboard",
    hx2 - t, hy1, HUB_BOX_TOP, hx2, hy2, HUB_BACKBOARD_TOP)

# Side panels (triangles extending from backboard toward alliance side)
b_hub_side_left = make_triangle("blue_hub_side_left",
    (hx2, hy1, HUB_BACKBOARD_TOP),   # top of backboard, left
    (BLUE_HUB_CX, hy1, HUB_BOX_TOP), # mid-HUB, left, at box top
    (hx2, hy1, HUB_BOX_TOP),          # base of backboard, left
)
b_hub_side_right = make_triangle("blue_hub_side_right",
    (hx2, hy2, HUB_BACKBOARD_TOP),   # top of backboard, right
    (hx2, hy2, HUB_BOX_TOP),          # base of backboard, right
    (BLUE_HUB_CX, hy2, HUB_BOX_TOP), # mid-HUB, right, at box top
)

hub_parts = [b_hub_alliance, b_hub_neutral_low, b_hub_neutral_high, b_hub_left, b_hub_right,
             b_hub_funnel, b_hub_ramp, b_hub_backboard,
             b_hub_side_left, b_hub_side_right]
for bh in hub_parts:
    elements.append(bh)
    elements.append(mirror_element(bh["name"].replace("blue_", "red_"), bh))

# --- 2 Depots ---
b_depot = make_box("blue_depot", 0, BLUE_DEPOT_Y1, 0, DEPOT_D, BLUE_DEPOT_Y2, DEPOT_H)
elements.append(b_depot)
elements.append(mirror_element("red_depot", b_depot))

# --- 2 Tower bases ---
b_tbase = make_box("blue_tower_base",
    0, TOWER_CY - TOWER_BASE_W/2, 0,
    TOWER_BASE_D, TOWER_CY + TOWER_BASE_W/2, TOWER_BASE_H)
elements.append(b_tbase)
elements.append(mirror_element("red_tower_base", b_tbase))

# --- 4 Tower uprights ---
ucx = UPRIGHT_CX_OFFSET
b_upr_l = make_box("blue_tower_upright_left",
    ucx - UPRIGHT_DEPTH/2, upright_left_cy - UPRIGHT_THICK/2, 0,
    ucx + UPRIGHT_DEPTH/2, upright_left_cy + UPRIGHT_THICK/2, UPRIGHT_H)
b_upr_r = make_box("blue_tower_upright_right",
    ucx - UPRIGHT_DEPTH/2, upright_right_cy - UPRIGHT_THICK/2, 0,
    ucx + UPRIGHT_DEPTH/2, upright_right_cy + UPRIGHT_THICK/2, UPRIGHT_H)
elements.append(b_upr_l)
elements.append(b_upr_r)
elements.append(mirror_element("red_tower_upright_left",  b_upr_l))
elements.append(mirror_element("red_tower_upright_right", b_upr_r))

# --- 6 Tower rungs ---
rung_half = RUNG_OD / 2
for rung_z, label in [(LOW_RUNG_Z, "low"), (MID_RUNG_Z, "mid"), (HIGH_RUNG_Z, "high")]:
    b_rung = make_box(f"blue_{label}_rung",
        ucx - rung_half, rung_y1, rung_z - rung_half,
        ucx + rung_half, rung_y2, rung_z + rung_half)
    elements.append(b_rung)
    elements.append(mirror_element(f"red_{label}_rung", b_rung))


# ============================================================
# Generate OBJ
# ============================================================
lines = []
lines.append("# 2026 REBUILT FRC Field - Simplified Collision Mesh")
lines.append("# All units in meters. Origin at blue-alliance / left-guardrail corner.")
lines.append("# X+ toward red alliance, Y+ across field, Z+ up")
lines.append(f"# Field: {FIELD_LENGTH}m x {FIELD_WIDTH}m")
lines.append(f"# Total elements: {len(elements)}")
lines.append("")

vertex_count = 0
total_faces = 0

for elem in elements:
    base = vertex_count

    lines.append(f"g {elem['name']}")

    for (x, y, z) in elem["verts"]:
        lines.append(f"v {x:.4f} {y:.4f} {z:.4f}")

    for face in elem["faces"]:
        idx_str = " ".join(str(base + i + 1) for i in face)
        lines.append(f"f {idx_str}")

    lines.append("")
    vertex_count += len(elem["verts"])
    total_faces += len(elem["faces"])

out_path = os.path.join(os.path.dirname(__file__), "field_collision.obj")
with open(out_path, "w") as f:
    f.write("\n".join(lines))

print(f"Generated {out_path}")
print(f"  {len(elements)} elements, {vertex_count} vertices, {total_faces} faces")
