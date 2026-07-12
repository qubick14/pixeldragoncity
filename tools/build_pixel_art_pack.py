#!/usr/bin/env python3
"""Generate a cohesive pixel-art asset pack for Pixel Dragon City.

All art shares one limited palette so backgrounds, characters, monsters and
items read as one world. Everything is drawn at 1x pixel scale (nearest-neighbor
upscaling happens in Godot), so shapes stay crisp.

Outputs (PNG, RGBA) into godot/assets/... :
  backgrounds/greenwood_village_bg.png
  backgrounds/black_wolf_forest_bg.png
  sprites/swordsman/swordsman_pixel_atlas.png   (4 cols x 9 rows)
  sprites/wolf_pixel_atlas.png                   (4 cols x 9 rows)
  items/item_icons_pixel_sheet.png              (32px grid)

Run:  python3 tools/build_pixel_art_pack.py
"""
from __future__ import annotations

import math
import os
import random
from PIL import Image, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT_ASSETS = os.path.join(ROOT, "godot", "assets")

# --------------------------------------------------------------------------
# Shared palette (R, G, B). Cozy 16-bit RPG feel: warm greens, earthy browns.
# --------------------------------------------------------------------------
PAL = {
    # grass / foliage
    "grass_dk": (58, 104, 61),
    "grass":    (86, 140, 74),
    "grass_lt": (120, 174, 90),
    "grass_hi": (156, 200, 110),
    # forest floor (darker, mossier)
    "moss_dk":  (40, 74, 52),
    "moss":     (58, 96, 62),
    "moss_lt":  (82, 120, 74),
    # dirt / path
    "dirt_dk":  (104, 78, 50),
    "dirt":     (140, 106, 66),
    "dirt_lt":  (170, 134, 88),
    "dirt_hi":  (196, 162, 112),
    # wood / structures
    "wood_dk":  (92, 62, 40),
    "wood":     (132, 92, 56),
    "wood_lt":  (170, 124, 78),
    "roof":     (150, 66, 54),
    "roof_dk":  (110, 46, 42),
    "roof_lt":  (186, 96, 78),
    "thatch":   (176, 146, 78),
    # tree
    "bark_dk":  (74, 52, 36),
    "bark":     (104, 74, 48),
    "leaf_dk":  (44, 92, 54),
    "leaf":     (66, 124, 64),
    "leaf_lt":  (98, 158, 82),
    "leaf_hi":  (134, 188, 104),
    # character skin / cloth / metal
    "skin_dk":  (176, 122, 84),
    "skin":     (222, 168, 122),
    "skin_hi":  (244, 200, 158),
    "hair_dk":  (70, 46, 32),
    "hair":     (104, 70, 42),
    "tunic_dk": (48, 92, 128),
    "tunic":    (72, 128, 172),
    "tunic_hi": (108, 168, 208),
    "leather_dk": (96, 62, 40),
    "leather":  (138, 92, 54),
    "steel_dk": (96, 104, 120),
    "steel":    (150, 158, 172),
    "steel_hi": (206, 212, 222),
    "gold":     (214, 176, 74),
    "gold_hi":  (244, 214, 120),
    # wolf
    "fur_dk":   (54, 54, 62),
    "fur":      (84, 84, 96),
    "fur_lt":   (120, 120, 134),
    "fur_boss_dk": (34, 32, 40),
    "fur_boss": (58, 56, 68),
    "fur_boss_lt": (92, 90, 104),
    "eye_red":  (206, 72, 60),
    "fang":     (232, 230, 222),
    # misc
    "shadow":   (0, 0, 0, 70),
    "outline":  (34, 30, 34),
    "potion_r": (208, 68, 74),
    "potion_g": (86, 176, 96),
    "flower_r": (206, 92, 96),
    "flower_y": (226, 200, 96),
    "flower_p": (170, 116, 190),
    "water_dk": (52, 96, 132),
    "water":    (84, 138, 176),
    "water_hi": (132, 182, 208),
    "rock_dk":  (90, 94, 100),
    "rock":     (128, 132, 138),
    "rock_hi":  (168, 172, 178),
}


def c(name):
    v = PAL[name]
    return v if len(v) == 4 else (v[0], v[1], v[2], 255)


def new_img(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def save(img, *parts):
    path = os.path.join(GODOT_ASSETS, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    img.save(path)
    print("wrote", os.path.relpath(path, ROOT), img.size)
    return path


# --------------------------------------------------------------------------
# Ground texture helpers
# --------------------------------------------------------------------------
def fill_ground(draw, w, h, base, speckles, rng, density=0.10, blade=None):
    """Flat base colour with blocky 2x2 dither patches + grass tufts.

    Blocky patches (instead of per-pixel static) read as intentional pixel art.
    `blade`, if given, is a colour used to stipple short vertical grass tufts.
    """
    draw.rectangle([0, 0, w, h], fill=base)
    # 2x2 dither patches
    for by in range(0, h, 2):
        for bx in range(0, w, 2):
            if rng.random() < density:
                col = rng.choice(speckles)
                draw.rectangle([bx, by, bx + 1, by + 1], fill=col)
    # scattered grass tufts (three-pixel little blades)
    if blade is not None:
        for _ in range(int(w * h * 0.0016)):
            x = rng.randint(2, w - 3)
            y = rng.randint(2, h - 3)
            draw.point((x, y), fill=blade)
            draw.point((x, y - 1), fill=blade)
            draw.point((x - 1, y), fill=blade)
            draw.point((x + 1, y - 1), fill=blade)


def draw_path(draw, points, half_width, base, edge, spec, rng):
    """Draw a soft dirt path along a polyline (list of (x,y))."""
    # thick line segments
    for i in range(len(points) - 1):
        x0, y0 = points[i]
        x1, y1 = points[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for s in range(steps + 1):
            t = s / steps
            cx = x0 + (x1 - x0) * t
            cy = y0 + (y1 - y0) * t
            r = half_width + rng.randint(-2, 2)
            draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=base)
    # speckle + edge highlight pass over the painted area is approximated by
    # scattering lighter/darker pebbles near the centre line
    for i in range(len(points) - 1):
        x0, y0 = points[i]
        x1, y1 = points[i + 1]
        steps = int(max(abs(x1 - x0), abs(y1 - y0))) + 1
        for s in range(0, steps + 1, 2):
            t = s / steps
            cx = int(x0 + (x1 - x0) * t)
            cy = int(y0 + (y1 - y0) * t)
            for _ in range(int(half_width * 0.9)):
                px = cx + rng.randint(-half_width, half_width)
                py = cy + rng.randint(-half_width, half_width)
                if (px - cx) ** 2 + (py - cy) ** 2 <= (half_width - 1) ** 2:
                    draw.point((px, py), fill=rng.choice(spec))


def stamp_tree(img, cx, cy, scale=1, boss=False):
    """Stamp a chunky pixel tree centred on trunk base at (cx, cy)."""
    d = ImageDraw.Draw(img)
    s = scale
    # shadow
    d.ellipse([cx - 14 * s, cy - 4 * s, cx + 14 * s, cy + 5 * s], fill=c("shadow"))
    ol = c("outline")
    leaf_dk = c("leaf_dk")
    leaf = c("leaf")
    leaf_lt = c("leaf_lt")
    leaf_hi = c("leaf_hi")
    blobs = [(-12, -30, 16), (10, -30, 16), (-1, -44, 20), (-1, -26, 20)]
    # outline pass: silhouette drawn 1px larger in dark, so a border peeks out
    d.rectangle([cx - 4 * s - 1, cy - 18 * s, cx + 4 * s + 1, cy + 1], fill=ol)
    for bx, by, br in blobs:
        d.ellipse([cx + bx * s - br * s - 1, cy + by * s - br * s - 1,
                   cx + bx * s + br * s + 1, cy + by * s + br * s + 1], fill=ol)
    # trunk
    d.rectangle([cx - 4 * s, cy - 18 * s, cx + 4 * s, cy], fill=c("bark"))
    d.rectangle([cx - 4 * s, cy - 18 * s, cx - 1 * s, cy], fill=c("bark_dk"))
    # canopy: three overlapping blobs
    for bx, by, br in blobs:
        d.ellipse([cx + bx * s - br * s, cy + by * s - br * s,
                   cx + bx * s + br * s, cy + by * s + br * s], fill=leaf_dk)
    for bx, by, br in blobs:
        rr = (br - 3)
        d.ellipse([cx + bx * s - rr * s, cy + by * s - rr * s,
                   cx + bx * s + rr * s, cy + by * s + rr * s], fill=leaf)
    # highlights (upper-left)
    for bx, by, br in blobs:
        rr = (br - 7)
        d.ellipse([cx + bx * s - rr * s - 3 * s, cy + by * s - rr * s - 3 * s,
                   cx + bx * s + rr * s - 3 * s, cy + by * s + rr * s - 3 * s], fill=leaf_lt)
    # sparkle dabs
    rng = random.Random(int(cx * 13 + cy * 7))
    for _ in range(18 * s):
        bx, by, br = rng.choice(blobs)
        px = cx + int((bx + rng.randint(-br + 4, br - 8)) * s)
        py = cy + int((by + rng.randint(-br + 4, br - 8)) * s)
        d.point((px, py), fill=leaf_hi)


def stamp_hut(img, cx, cy, roof_color, roof_dk, roof_lt):
    d = ImageDraw.Draw(img)
    # shadow
    d.ellipse([cx - 44, cy + 22, cx + 44, cy + 38], fill=c("shadow"))
    # outline pass: wall + roof silhouette drawn slightly larger in dark
    ol = c("outline")
    d.rectangle([cx - 37, cy - 6, cx + 37, cy + 31], fill=ol)
    d.polygon([(cx - 48, cy - 3), (cx, cy - 42), (cx + 48, cy - 3)], fill=ol)
    # walls
    d.rectangle([cx - 36, cy - 6, cx + 36, cy + 30], fill=c("wood"))
    d.rectangle([cx - 36, cy - 6, cx + 36, cy + 2], fill=c("wood_lt"))
    # plank lines
    for px in range(cx - 30, cx + 36, 12):
        d.line([px, cy - 6, px, cy + 30], fill=c("wood_dk"))
    # door
    d.rectangle([cx - 8, cy + 8, cx + 8, cy + 30], fill=c("wood_dk"))
    d.rectangle([cx - 6, cy + 10, cx + 6, cy + 30], fill=c("bark_dk"))
    # window
    d.rectangle([cx + 16, cy + 6, cx + 28, cy + 16], fill=c("bark_dk"))
    d.rectangle([cx + 18, cy + 8, cx + 26, cy + 14], fill=(120, 150, 120, 255))
    # roof (triangle)
    d.polygon([(cx - 46, cy - 4), (cx, cy - 40), (cx + 46, cy - 4)], fill=roof_color)
    d.polygon([(cx - 46, cy - 4), (cx, cy - 40), (cx - 4, cy - 4)], fill=roof_dk)
    d.polygon([(cx + 4, cy - 34), (cx, cy - 40), (cx + 8, cy - 30)], fill=roof_lt)
    # roof ridge shading lines
    for i in range(1, 6):
        d.line([cx - 46 + i * 3, cy - 4, cx, cy - 40], fill=roof_dk)


def scatter_flowers(img, w, h, avoid, rng, n=90):
    d = ImageDraw.Draw(img)
    cols = [c("flower_r"), c("flower_y"), c("flower_p")]
    for _ in range(n):
        x = rng.randint(6, w - 6)
        y = rng.randint(6, h - 6)
        if avoid(x, y):
            continue
        col = rng.choice(cols)
        d.point((x, y), fill=col)
        d.point((x + 1, y), fill=col)
        d.point((x, y + 1), fill=c("grass_hi"))


def scatter_rocks(img, w, h, avoid, rng, n=30):
    d = ImageDraw.Draw(img)
    for _ in range(n):
        x = rng.randint(8, w - 8)
        y = rng.randint(8, h - 8)
        if avoid(x, y):
            continue
        r = rng.randint(2, 4)
        d.ellipse([x - r, y - r, x + r, y + r], fill=c("rock"))
        d.ellipse([x - r, y - r, x + r - 1, y + r - 1], fill=c("rock_hi"))
        d.point((x + r - 1, y + r - 1), fill=c("rock_dk"))


# --------------------------------------------------------------------------
# Backgrounds
# --------------------------------------------------------------------------
def build_greenwood_village():
    # Village map bounds ~1500x900 centred at origin. Render 1600x960, origin at centre.
    W, H = 1600, 960
    img = new_img(W, H)
    d = ImageDraw.Draw(img)
    rng = random.Random(20260710)
    fill_ground(d, W, H, c("grass"),
                [c("grass_dk"), c("grass_lt")], rng, density=0.10, blade=c("grass_hi"))

    # winding dirt path (local coords -> image coords: +W/2, +H/2)
    def L(x, y):
        return (x + W // 2, y + H // 2)
    path = [L(-620, 190), L(-380, 150), L(-120, 60), L(120, 40), L(360, 10), L(560, 20)]
    draw_path(d, path, 34, c("dirt"),
              c("dirt_lt"), [c("dirt_dk"), c("dirt_lt"), c("dirt_hi")], rng)

    def near_path(x, y):
        # cheap avoidance: within band of the path
        for (px, py) in path:
            if (x - px) ** 2 + (y - py) ** 2 < 46 ** 2:
                return True
        return False

    scatter_flowers(img, W, H, near_path, rng, n=120)
    scatter_rocks(img, W, H, near_path, rng, n=26)

    # huts (village) - positions echo original scene (chief hut area)
    stamp_hut(img, *L(-120, -150), c("roof"), c("roof_dk"), c("roof_lt"))
    stamp_hut(img, *L(120, -60), c("thatch"), c("wood_dk"), c("dirt_hi"))
    stamp_hut(img, *L(300, -180), c("roof"), c("roof_dk"), c("roof_lt"))

    # border trees (frame the play area)
    tx, ty = W // 2, H // 2
    tree_spots = []
    for x in range(-720, 760, 120):
        tree_spots.append((x, -400 + rng.randint(-16, 16)))
        tree_spots.append((x, 400 + rng.randint(-16, 16)))
    for y in range(-330, 360, 130):
        tree_spots.append((-700 + rng.randint(-16, 16), y))
        tree_spots.append((700 + rng.randint(-16, 16), y))
    # a few interior trees
    tree_spots += [(-420, -240), (420, 220), (-500, 250), (480, -300)]
    for (x, y) in tree_spots:
        stamp_tree(img, tx + x, ty + y, scale=1)

    return save(img, "backgrounds", "greenwood_village_bg.png")


def build_black_wolf_forest():
    W, H = 1760, 1040
    img = new_img(W, H)
    d = ImageDraw.Draw(img)
    rng = random.Random(66613)
    fill_ground(d, W, H, c("moss"),
                [c("moss_dk"), c("grass_dk")], rng, density=0.12, blade=c("moss_lt"))

    def L(x, y):
        return (x + W // 2, y + H // 2)

    # boss clearing: lighter patch upper-right
    d.ellipse([L(320, -320)[0], L(320, -320)[1], L(760, 60)[0], L(760, 60)[1]],
              fill=c("moss_lt"))

    trail = [L(-740, 220), L(-430, 130), L(-120, 60), L(220, -40), L(520, -140), L(700, -120)]
    draw_path(d, trail, 30, c("dirt_dk"),
              c("dirt"), [c("dirt_dk"), c("dirt"), c("dirt_lt")], rng)

    def near_trail(x, y):
        for (px, py) in trail:
            if (x - px) ** 2 + (y - py) ** 2 < 42 ** 2:
                return True
        return False

    scatter_rocks(img, W, H, near_trail, rng, n=44)
    # dark mushrooms / underbrush dabs
    for _ in range(140):
        x = rng.randint(6, W - 6); y = rng.randint(6, H - 6)
        if near_trail(x, y):
            continue
        d.point((x, y), fill=c("moss_dk"))
        d.point((x, y - 1), fill=c("eye_red") if rng.random() < 0.06 else c("moss_dk"))

    tx, ty = W // 2, H // 2
    # dense border + scattered interior trees (darker forest)
    spots = []
    for x in range(-800, 840, 96):
        spots.append((x, -450 + rng.randint(-20, 20)))
        spots.append((x, 450 + rng.randint(-20, 20)))
    for y in range(-380, 400, 104):
        spots.append((-780 + rng.randint(-20, 20), y))
        spots.append((780 + rng.randint(-20, 20), y))
    for _ in range(26):
        x = rng.randint(-680, 680); y = rng.randint(-360, 360)
        if not near_trail(tx + x, ty + y):
            spots.append((x, y))
    for (x, y) in spots:
        stamp_tree(img, tx + x, ty + y, scale=1, boss=True)

    return save(img, "backgrounds", "black_wolf_forest_bg.png")


# --------------------------------------------------------------------------
# Character: swordsman walk atlas (4 cols x 9 rows), 32x40 cells.
# Rows map to player_controller.get_test_atlas_row():
#   0 down, 1 down_left, 2 left, 3 up_left, 4 up, 5 up_right, 6 right,
#   7 down_right, 8 idle(=down). No horizontal flip is applied by the game,
#   so left and right are drawn separately.
# --------------------------------------------------------------------------
CELL_W, CELL_H = 32, 40


def _leg_phase(frame):
    """Return (left_dy, right_dy, swing) for a 4-frame contact/passing walk."""
    # frame 0 contact(left fwd), 1 passing, 2 contact(right fwd), 3 passing
    table = {0: (2, -1, 3), 1: (0, 0, 0), 2: (-1, 2, -3), 3: (0, 0, 0)}
    return table[frame]


def _body_bob(frame):
    return {0: 0, 1: -1, 2: 0, 3: -1}[frame]


def draw_hero_front(d, ox, oy, frame, back=False, with_sword=True):
    bob = _body_bob(frame)
    ldy, rdy, _ = _leg_phase(frame)
    cx = ox + 16
    # legs (pants + boots)
    d.rectangle([cx - 5, oy + 27 + bob, cx - 2, oy + 33 + ldy], fill=c("leather"))
    d.rectangle([cx + 1, oy + 27 + bob, cx + 4, oy + 33 + rdy], fill=c("leather_dk"))
    d.rectangle([cx - 5, oy + 32 + ldy, cx - 2, oy + 34 + ldy], fill=c("outline"))
    d.rectangle([cx + 1, oy + 32 + rdy, cx + 4, oy + 34 + rdy], fill=c("outline"))
    # torso (tunic)
    d.rectangle([cx - 5, oy + 16 + bob, cx + 4, oy + 27 + bob], fill=c("tunic"))
    d.rectangle([cx - 5, oy + 16 + bob, cx - 3, oy + 27 + bob], fill=c("tunic_dk"))
    d.rectangle([cx + 2, oy + 16 + bob, cx + 4, oy + 27 + bob], fill=c("tunic_hi"))
    # belt
    d.rectangle([cx - 5, oy + 25 + bob, cx + 4, oy + 26 + bob], fill=c("leather_dk"))
    d.point((cx, oy + 25 + bob), fill=c("gold"))
    # arms
    d.rectangle([cx - 7, oy + 17 + bob, cx - 5, oy + 24 + bob], fill=c("skin_dk"))
    d.rectangle([cx + 4, oy + 17 + bob, cx + 6, oy + 24 + bob], fill=c("skin"))
    # head
    d.rectangle([cx - 4, oy + 8 + bob, cx + 3, oy + 16 + bob], fill=c("skin"))
    d.rectangle([cx + 2, oy + 8 + bob, cx + 3, oy + 16 + bob], fill=c("skin_dk"))
    d.rectangle([cx - 4, oy + 8 + bob, cx - 3, oy + 12 + bob], fill=c("skin_hi"))
    # hair
    d.rectangle([cx - 5, oy + 5 + bob, cx + 4, oy + 9 + bob], fill=c("hair"))
    d.rectangle([cx - 5, oy + 5 + bob, cx + 4, oy + 6 + bob], fill=c("hair_dk"))
    if not back:
        # face: side fringe + two eyes
        d.rectangle([cx - 5, oy + 8 + bob, cx - 4, oy + 11 + bob], fill=c("hair"))
        d.rectangle([cx + 3, oy + 8 + bob, cx + 4, oy + 11 + bob], fill=c("hair"))
        d.point((cx - 2, oy + 12 + bob), fill=c("outline"))
        d.point((cx + 1, oy + 12 + bob), fill=c("outline"))
    else:
        # back of head: full hair
        d.rectangle([cx - 4, oy + 8 + bob, cx + 3, oy + 15 + bob], fill=c("hair"))
        d.rectangle([cx - 4, oy + 8 + bob, cx - 2, oy + 15 + bob], fill=c("hair_dk"))
    # sword on right side (blade down)
    if with_sword:
        sx = cx + 6
        d.rectangle([sx, oy + 22 + bob, sx + 1, oy + 24 + bob], fill=c("leather_dk"))  # grip
        d.rectangle([sx - 1, oy + 24 + bob, sx + 2, oy + 25 + bob], fill=c("gold"))    # guard
        d.rectangle([sx, oy + 25 + bob, sx + 1, oy + 34 + bob], fill=c("steel"))       # blade
        d.point((sx, oy + 25 + bob), fill=c("steel_hi"))


def draw_hero_side(d, ox, oy, frame, facing_left, with_sword=True):
    """Side profile. Draw facing-right internally, mirror if facing_left."""
    cell = new_img(CELL_W, CELL_H)
    dd = ImageDraw.Draw(cell)
    bob = _body_bob(frame)
    ldy, rdy, swing = _leg_phase(frame)
    cx = 15
    # legs swing front/back
    dd.rectangle([cx - 3 + swing, 27 + bob, cx, 34], fill=c("leather"))
    dd.rectangle([cx - 1 - swing, 27 + bob, cx + 2 - swing, 34], fill=c("leather_dk"))
    dd.rectangle([cx - 3 + swing, 33, cx, 34], fill=c("outline"))
    dd.rectangle([cx - 1 - swing, 33, cx + 2 - swing, 34], fill=c("outline"))
    # torso
    dd.rectangle([cx - 3, 16 + bob, cx + 2, 27 + bob], fill=c("tunic"))
    dd.rectangle([cx + 1, 16 + bob, cx + 2, 27 + bob], fill=c("tunic_hi"))
    dd.rectangle([cx - 3, 16 + bob, cx - 2, 27 + bob], fill=c("tunic_dk"))
    dd.rectangle([cx - 3, 25 + bob, cx + 2, 26 + bob], fill=c("leather_dk"))
    # head (face pointing right)
    dd.rectangle([cx - 2, 8 + bob, cx + 4, 16 + bob], fill=c("skin"))
    dd.rectangle([cx + 3, 8 + bob, cx + 4, 16 + bob], fill=c("skin_hi"))
    dd.point((cx + 3, 12 + bob), fill=c("outline"))  # eye
    # hair (back of head, left side)
    dd.rectangle([cx - 3, 5 + bob, cx + 3, 9 + bob], fill=c("hair"))
    dd.rectangle([cx - 3, 5 + bob, cx + 1, 7 + bob], fill=c("hair_dk"))
    dd.rectangle([cx - 3, 8 + bob, cx - 1, 13 + bob], fill=c("hair"))
    # forward arm + sword extended forward (right)
    if with_sword:
        dd.rectangle([cx + 2, 18 + bob, cx + 6, 20 + bob], fill=c("skin"))
        dd.rectangle([cx + 6, 17 + bob, cx + 7, 20 + bob], fill=c("gold"))     # guard
        dd.rectangle([cx + 7, 18 + bob, cx + 15, 19 + bob], fill=c("steel"))  # blade forward
        dd.point((cx + 14, 18 + bob), fill=c("steel_hi"))
    if facing_left:
        cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
    return cell


def _finish_cell(cell):
    """Stardew-style finish: 1px dark outline around the silhouette, soft ground
    shadow composited beneath (so the shadow itself is not outlined)."""
    _outline_cell(cell)
    base = new_img(CELL_W, CELL_H)
    ImageDraw.Draw(base).ellipse([9, 33, 23, 38], fill=c("shadow"))
    return Image.alpha_composite(base, cell)


def build_swordsman_atlas():
    cols, rows = 4, 9
    atlas = new_img(CELL_W * cols, CELL_H * rows)
    # row -> ('front'|'back'|'left'|'right')
    row_kind = ["front", "left", "left", "back", "back", "back", "right", "right", "front"]
    for r, kind in enumerate(row_kind):
        for f in range(cols):
            if kind in ("front", "back"):
                cell = new_img(CELL_W, CELL_H)
                draw_hero_front(ImageDraw.Draw(cell), 0, 0, f, back=(kind == "back"))
            else:
                cell = draw_hero_side(None, 0, 0, f, facing_left=(kind == "left"))
            cell = _finish_cell(cell)
            atlas.paste(cell, (f * CELL_W, r * CELL_H), cell)
    return save(atlas, "sprites", "swordsman", "swordsman_pixel_atlas.png")


# --------------------------------------------------------------------------
# Swordsman ATTACK atlas (4 cols x 9 rows), same cells/layout as the walk
# atlas. The 4 columns are a swing: windup -> strike -> recover, with a bright
# slash arc on the strike frames. Controller swaps to this sheet during ATTACK.
# --------------------------------------------------------------------------
_SLASH_COLS = [(255, 250, 220, 255), (245, 225, 150, 255), (228, 196, 118, 255)]


def _draw_slash_arc(d, cx, cy, radius, start_deg, end_deg, colors=_SLASH_COLS):
    for i, col in enumerate(colors):
        r = radius - i
        if r <= 1:
            break
        d.arc([cx - r, cy - r, cx + r, cy + r], start_deg, end_deg, fill=col, width=2)


def _draw_swing_blade(d, hx, hy, angle_deg, length):
    a = math.radians(angle_deg)
    ex = hx + int(round(math.cos(a) * length))
    ey = hy + int(round(math.sin(a) * length))
    d.ellipse([hx - 2, hy - 2, hx + 2, hy + 2], fill=c("gold"))  # guard
    d.line([(hx, hy), (ex, ey)], fill=c("steel"), width=2)
    d.line([(hx, hy), (ex, ey)], fill=c("steel_hi"))
    d.point((ex, ey), fill=c("steel_hi"))


# Slash/blade overlays are drawn on top of the already-outlined character so the
# bright arc keeps its glow (no dark outline around it).
def _attack_front_overlay(cd, frame, back):
    hx, hy = 21, 19  # sword hand (cell-local)
    base_angles = [-80, -30, 40, 75]  # downward swing (front view)
    lengths = [12, 15, 18, 13]
    angle = -base_angles[frame] if back else base_angles[frame]
    _draw_swing_blade(cd, hx, hy, angle, lengths[frame])
    if frame in (1, 2):
        radius = 22 if frame == 2 else 16
        arc_cy = 10 if back else 24
        a0, a1 = (120, 235) if back else (-52, 62)
        _draw_slash_arc(cd, 16, arc_cy, radius, a0, a1)


def _attack_side_overlay(cd, frame):
    hx, hy = 17, 19
    lengths = [8, 14, 19, 12]
    angles = [-22, -6, 6, 26]
    _draw_swing_blade(cd, hx, hy, angles[frame], lengths[frame])
    if frame in (1, 2):
        radius = 13 if frame == 2 else 9
        _draw_slash_arc(cd, 24, 19, radius, -72, 72)


def _draw_villager(cd, skin, hair, hair_dk, top, top_dk, top_hi, bottom, long_robe=False, prop=None):
    cx = 16
    ol = c("outline")
    # lower body
    if long_robe:
        cd.polygon([(cx - 6, 25), (cx + 5, 25), (cx + 7, 34), (cx - 8, 34)], fill=bottom)
        cd.polygon([(cx - 6, 25), (cx - 1, 25), (cx - 3, 34), (cx - 8, 34)], fill=top_dk)
        cd.rectangle([cx - 4, 33, cx - 1, 34], fill=c("leather_dk"))
        cd.rectangle([cx + 1, 33, cx + 4, 34], fill=c("leather_dk"))
    else:
        cd.rectangle([cx - 5, 27, cx - 1, 33], fill=bottom)
        cd.rectangle([cx + 1, 27, cx + 5, 33], fill=bottom)
        cd.rectangle([cx - 5, 32, cx - 1, 34], fill=c("leather_dk"))
        cd.rectangle([cx + 1, 32, cx + 5, 34], fill=c("leather_dk"))
    # torso (3-tone)
    cd.rectangle([cx - 5, 15, cx + 4, 27], fill=top)
    cd.rectangle([cx - 5, 15, cx - 3, 27], fill=top_dk)
    cd.rectangle([cx + 2, 15, cx + 4, 27], fill=top_hi)
    cd.rectangle([cx - 5, 25, cx + 4, 26], fill=c("leather_dk"))  # belt
    # arms + hands
    cd.rectangle([cx - 7, 16, cx - 5, 24], fill=top_dk)
    cd.rectangle([cx + 4, 16, cx + 6, 24], fill=top)
    cd.rectangle([cx - 7, 23, cx - 5, 25], fill=skin)
    cd.rectangle([cx + 4, 23, cx + 6, 25], fill=skin)
    # head
    cd.rectangle([cx - 4, 7, cx + 3, 15], fill=skin)
    cd.rectangle([cx + 2, 7, cx + 3, 15], fill=_shade(skin, -22))
    cd.rectangle([cx - 4, 7, cx - 3, 11], fill=_shade(skin, 16))
    cd.point((cx - 2, 11), fill=ol)
    cd.point((cx + 1, 11), fill=ol)
    # hair
    cd.rectangle([cx - 5, 4, cx + 4, 9], fill=hair)
    cd.rectangle([cx - 5, 4, cx + 4, 5], fill=hair_dk)
    cd.rectangle([cx - 5, 7, cx - 4, 11], fill=hair)
    cd.rectangle([cx + 3, 7, cx + 4, 11], fill=hair)
    # prop
    if prop == "staff":
        cd.rectangle([cx + 6, 5, cx + 7, 31], fill=c("wood_dk"))
        cd.ellipse([cx + 5, 3, cx + 9, 7], fill=c("gold"))
        cd.point((cx + 6, 4), fill=c("gold_hi"))
    elif prop == "hammer":
        cd.rectangle([cx + 6, 12, cx + 7, 25], fill=c("wood_dk"))
        cd.rectangle([cx + 4, 9, cx + 9, 13], fill=c("steel"))
        cd.rectangle([cx + 4, 9, cx + 9, 10], fill=c("steel_hi"))
    elif prop == "pack":
        cd.rectangle([cx - 10, 15, cx - 6, 26], fill=c("leather"))
        cd.rectangle([cx - 10, 15, cx - 6, 17], fill=c("leather_dk"))
        cd.rectangle([cx - 9, 19, cx - 7, 21], fill=c("gold"))


def build_npcs():
    rgba = lambda r, g, b: (r, g, b, 255)
    specs = {
        "npc_village_chief": dict(skin=c("skin"), hair=rgba(184, 182, 188), hair_dk=rgba(126, 126, 134),
            top=rgba(124, 46, 54), top_dk=rgba(84, 30, 38), top_hi=rgba(154, 66, 76),
            bottom=rgba(94, 36, 44), long_robe=True, prop="staff"),
        "npc_merchant": dict(skin=c("skin"), hair=rgba(98, 66, 42), hair_dk=rgba(64, 42, 28),
            top=rgba(60, 112, 72), top_dk=rgba(40, 78, 50), top_hi=rgba(86, 142, 98),
            bottom=rgba(72, 58, 40), prop="pack"),
        "npc_blacksmith": dict(skin=rgba(198, 152, 122), hair=rgba(42, 38, 36), hair_dk=rgba(24, 22, 20),
            top=rgba(76, 76, 84), top_dk=rgba(50, 50, 56), top_hi=rgba(100, 100, 110),
            bottom=rgba(54, 46, 42), prop="hammer"),
    }
    for name, s in specs.items():
        cell = new_img(CELL_W, CELL_H)
        _draw_villager(ImageDraw.Draw(cell), s["skin"], s["hair"], s["hair_dk"],
            s["top"], s["top_dk"], s["top_hi"], s["bottom"], s.get("long_robe", False), s.get("prop"))
        cell = _finish_cell(cell)
        save(cell, "sprites", "npc", name + ".png")


def build_swordsman_attack_atlas():
    cols, rows = 4, 9
    atlas = new_img(CELL_W * cols, CELL_H * rows)
    row_kind = ["front", "left", "left", "back", "back", "back", "right", "right", "front"]
    for r, kind in enumerate(row_kind):
        for f in range(cols):
            if kind in ("front", "back"):
                cell = new_img(CELL_W, CELL_H)
                draw_hero_front(ImageDraw.Draw(cell), 0, 0, 1, back=(kind == "back"), with_sword=False)
                cell = _finish_cell(cell)
                _attack_front_overlay(ImageDraw.Draw(cell), f, back=(kind == "back"))
            else:
                cell = draw_hero_side(None, 0, 0, 1, facing_left=False, with_sword=False)
                cell = _finish_cell(cell)
                _attack_side_overlay(ImageDraw.Draw(cell), f)
                if kind == "left":
                    cell = cell.transpose(Image.FLIP_LEFT_RIGHT)
            atlas.paste(cell, (f * CELL_W, r * CELL_H), cell)
    return save(atlas, "sprites", "swordsman", "swordsman_attack_pixel_atlas.png")


# --------------------------------------------------------------------------
# Monster: side-profile wolf (faces LEFT). Controller flips horizontally to
# face movement and cycles the 4 frames while chasing. Cells are 64x40; the
# black wolf leader is a bulkier, darker boss variant (own sheet).
# --------------------------------------------------------------------------
WOLF_W, WOLF_H, WOLF_FRAMES = 64, 40, 4


def _wolf_leg_lift(frame):
    """Per-leg vertical lift for a 4-frame diagonal trot (front1, front2, back1, back2)."""
    table = {
        0: (0, 0, 0, 0),
        1: (-3, 0, 0, -3),
        2: (0, 0, 0, 0),
        3: (0, -3, -3, 0),
    }
    return table[frame]


def _shade(col, delta):
    return tuple(max(0, min(255, ch + delta)) for ch in col[:3]) + (255,)


def draw_wolf(d, ox, frame, boss=False):
    if boss:
        dk, mid, lt = c("fur_boss_dk"), c("fur_boss"), c("fur_boss_lt")
    else:
        dk, mid, lt = c("fur_dk"), c("fur"), c("fur_lt")
    deep = _shade(dk, -16)   # deepest shadow / outline-ish
    hi = _shade(lt, 22)      # brightest fur highlight
    ol = c("outline")
    bob = {0: 0, 1: -1, 2: 0, 3: -1}[frame]
    oy = bob
    # bushy tail with a couple of fur strands
    d.polygon([(ox + 48, oy + 22), (ox + 61, oy + 6), (ox + 63, oy + 13), (ox + 54, oy + 27)], fill=deep)
    d.polygon([(ox + 48, oy + 22), (ox + 60, oy + 8), (ox + 62, oy + 14), (ox + 54, oy + 26)], fill=dk)
    d.polygon([(ox + 50, oy + 22), (ox + 58, oy + 12), (ox + 60, oy + 16), (ox + 53, oy + 25)], fill=mid)
    for sx, sy in [(59, 9), (61, 12), (57, 15)]:
        d.point((ox + sx, oy + sy), fill=lt)

    # legs (diagonal trot) with a lit front edge + toe
    lifts = _wolf_leg_lift(frame)
    for i, (lx, back) in enumerate([(20, False), (27, False), (41, True), (48, True)]):
        col = dk if back else mid
        top = oy + 26 + lifts[i]
        d.rectangle([ox + lx, top, ox + lx + 3, 34], fill=col)
        d.rectangle([ox + lx, top, ox + lx, 34], fill=_shade(col, 18))   # front-edge light
        d.rectangle([ox + lx + 3, top, ox + lx + 3, 34], fill=deep)      # back-edge shadow
        d.rectangle([ox + lx, 32, ox + lx + 3, 34], fill=deep)           # paw
        d.point((ox + lx, 33), fill=ol)

    # body: mid base, lit top band, dark belly, rounded haunch + shoulder
    d.rounded_rectangle([ox + 16, oy + 13, ox + 52, oy + 29], radius=6, fill=mid)
    d.rounded_rectangle([ox + 16, oy + 12, ox + 52, oy + 18], radius=5, fill=lt)
    d.rectangle([ox + 18, oy + 11, ox + 50, oy + 12], fill=hi)           # spine highlight
    d.rectangle([ox + 18, oy + 26, ox + 51, oy + 29], fill=deep)         # belly shadow
    d.ellipse([ox + 40, oy + 15, ox + 54, oy + 29], fill=mid)           # haunch mass
    d.ellipse([ox + 42, oy + 16, ox + 50, oy + 23], fill=lt)            # haunch light
    d.ellipse([ox + 17, oy + 15, ox + 28, oy + 27], fill=_shade(mid, 6))  # shoulder

    # fur texture: short diagonal strokes across the flank
    for fx in range(20, 50, 3):
        fy = oy + 20 + ((fx // 3) % 3)
        d.line([(ox + fx, fy), (ox + fx + 2, fy - 2)], fill=_shade(mid, -14))
        d.point((ox + fx + 1, fy - 1), fill=lt)

    # neck + head (faces left)
    d.polygon([(ox + 22, oy + 13), (ox + 8, oy + 13), (ox + 3, oy + 22), (ox + 10, oy + 28), (ox + 24, oy + 27)], fill=mid)
    d.polygon([(ox + 22, oy + 13), (ox + 8, oy + 13), (ox + 7, oy + 18), (ox + 22, oy + 18)], fill=lt)
    # neck ruff (fur under the jaw)
    for rx in range(9, 22, 3):
        d.line([(ox + rx, oy + 26), (ox + rx + 1, oy + 29)], fill=deep)
        d.point((ox + rx, oy + 26), fill=lt)
    # snout (tapered) + nose + jaw
    d.polygon([(ox + 8, oy + 18), (ox + 1, oy + 21), (ox + 1, oy + 25), (ox + 9, oy + 25)], fill=dk)
    d.polygon([(ox + 8, oy + 18), (ox + 3, oy + 20), (ox + 9, oy + 21)], fill=mid)
    d.rectangle([ox + 1, oy + 21, ox + 2, oy + 22], fill=ol)             # nose
    d.rectangle([ox + 2, oy + 24, ox + 8, oy + 25], fill=c("fang"))      # fangs
    d.point((ox + 4, oy + 24), fill=ol)
    d.point((ox + 6, oy + 24), fill=ol)
    # ears (with dark inner)
    d.polygon([(ox + 11, oy + 12), (ox + 14, oy + 2), (ox + 18, oy + 12)], fill=dk)
    d.polygon([(ox + 13, oy + 11), (ox + 14, oy + 5), (ox + 16, oy + 11)], fill=deep)
    d.polygon([(ox + 17, oy + 12), (ox + 20, oy + 4), (ox + 23, oy + 13)], fill=mid)
    d.polygon([(ox + 18, oy + 11), (ox + 20, oy + 6), (ox + 21, oy + 11)], fill=lt)
    # brow + eye (menacing)
    d.line([(ox + 10, oy + 15), (ox + 14, oy + 15)], fill=deep)
    d.rectangle([ox + 11, oy + 16, ox + 13, oy + 18], fill=c("eye_red"))
    d.point((ox + 12, oy + 16), fill=c("gold_hi"))

    # back fur tufts
    for tx in range(20, 50, 5):
        d.point((ox + tx, oy + 12), fill=lt)
        d.point((ox + tx + 1, oy + 11), fill=hi)

    if boss:
        # spiked mane, scar over the eye, brighter glare
        for mx in range(16, 50, 4):
            d.polygon([(ox + mx, oy + 12), (ox + mx + 2, oy + 3), (ox + mx + 4, oy + 12)], fill=deep)
            d.polygon([(ox + mx + 1, oy + 11), (ox + mx + 2, oy + 6), (ox + mx + 3, oy + 11)], fill=dk)
            d.point((ox + mx + 2, oy + 7), fill=lt)
        d.line([(ox + 9, oy + 13), (ox + 14, oy + 20)], fill=c("fang"))
        d.rectangle([ox + 11, oy + 16, ox + 13, oy + 18], fill=(255, 60, 40))
        d.point((ox + 12, oy + 16), fill=(255, 210, 120))


def _finish_wolf_cell(cell):
    """1px outline around the wolf, ground shadow composited beneath."""
    _outline_cell(cell)
    base = new_img(WOLF_W, WOLF_H)
    ImageDraw.Draw(base).ellipse([12, 33, 56, 39], fill=c("shadow"))
    return Image.alpha_composite(base, cell)


def _build_wolf_atlas(boss, filename):
    atlas = new_img(WOLF_W * WOLF_FRAMES, WOLF_H)
    for f in range(WOLF_FRAMES):
        cell = new_img(WOLF_W, WOLF_H)
        draw_wolf(ImageDraw.Draw(cell), 0, f, boss=boss)
        cell = _finish_wolf_cell(cell)
        atlas.paste(cell, (f * WOLF_W, 0), cell)
    return save(atlas, "sprites", filename)


def build_wolf_sheet():
    return _build_wolf_atlas(False, "wolf_pixel_sheet.png")


def build_wolf_boss_sheet():
    return _build_wolf_atlas(True, "wolf_boss_pixel_sheet.png")


# --------------------------------------------------------------------------
# Item icons: 32px cells in a single row. icon_index in items.json = column.
#   0 wooden_sword  1 iron_sword  2 cloth_armor
#   3 leather_armor 4 small_health_potion  5 wolf_pelt
# --------------------------------------------------------------------------
def _outline_cell(cell):
    """Add a 1px dark outline around opaque pixels (simple dilation)."""
    ol = c("outline")
    px = cell.load()
    w, h = cell.size
    edges = []
    for y in range(h):
        for x in range(w):
            if px[x, y][3] != 0:
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and px[nx, ny][3] != 0:
                    edges.append((x, y)); break
    for (x, y) in edges:
        px[x, y] = ol


def _icon_sword(d, blade_dk, blade, blade_hi):
    # diagonal sword, hilt lower-left, tip upper-right
    for i in range(18):
        x = 7 + i; y = 24 - i
        d.point((x, y), fill=blade)
        d.point((x - 1, y), fill=blade_dk)
        d.point((x, y - 1), fill=blade_hi)
    # guard
    d.line([(6, 22), (12, 26)], fill=c("gold"))
    # grip
    d.line([(5, 24), (8, 27)], fill=c("leather_dk"))
    d.point((4, 25), fill=c("gold_hi"))


def _icon_armor(d, main_dk, main, main_hi, trim):
    # simple cuirass / tunic silhouette
    d.polygon([(11, 8), (21, 8), (24, 12), (22, 26), (10, 26), (8, 12)], fill=main)
    d.polygon([(11, 8), (16, 8), (16, 26), (10, 26), (8, 12)], fill=main_dk)
    d.polygon([(20, 9), (24, 12), (22, 22)], fill=main_hi)
    # shoulders
    d.rectangle([7, 9, 10, 13], fill=main_hi)
    d.rectangle([22, 9, 25, 13], fill=main_dk)
    # neck + belt trim
    d.rectangle([13, 6, 19, 9], fill=trim)
    d.rectangle([9, 22, 23, 24], fill=trim)


def _icon_potion(d):
    # round red potion with cork
    d.ellipse([9, 14, 23, 27], fill=c("potion_r"))
    d.ellipse([11, 16, 18, 22], fill=(240, 150, 150, 255))
    d.rectangle([13, 8, 19, 15], fill=(180, 70, 74, 255))    # neck
    d.rectangle([12, 15, 20, 17], fill=c("potion_r"))
    d.rectangle([13, 5, 19, 9], fill=c("leather"))           # cork
    d.point((13, 18), fill=(255, 220, 220, 255))             # glint


def _icon_pelt(d):
    dk, mid, lt = c("fur_dk"), c("fur"), c("fur_lt")
    d.polygon([(8, 12), (16, 8), (24, 12), (26, 22), (16, 26), (6, 22)], fill=mid)
    d.polygon([(8, 12), (16, 8), (16, 26), (6, 22)], fill=dk)
    d.polygon([(20, 11), (24, 12), (24, 20)], fill=lt)
    # paws / limbs
    for pxp in [(6, 14), (26, 14), (10, 25), (22, 25)]:
        d.rectangle([pxp[0] - 1, pxp[1], pxp[0] + 1, pxp[1] + 2], fill=dk)
    d.point((13, 15), fill=c("eye_red"))


def _icon_coin(d):
    d.ellipse([9, 9, 23, 23], fill=c("gold"))
    d.ellipse([9, 9, 23, 23], outline=c("wood_dk"))
    d.ellipse([11, 11, 21, 21], fill=c("gold_hi"))
    d.ellipse([13, 13, 19, 19], fill=c("gold"))
    d.point((13, 12), fill=(255, 245, 210, 255))


def build_item_icons():
    n = 8
    sheet = new_img(32 * n, 32)
    for idx in range(n):
        cell = new_img(32, 32)
        d = ImageDraw.Draw(cell)
        if idx == 0:
            _icon_sword(d, c("wood_dk"), c("wood_lt"), c("dirt_hi"))
        elif idx == 1:
            _icon_sword(d, c("steel_dk"), c("steel"), c("steel_hi"))
        elif idx == 2:
            _icon_armor(d, c("tunic_dk"), c("tunic"), c("tunic_hi"), c("thatch"))
        elif idx == 3:
            _icon_armor(d, c("leather_dk"), c("leather"), c("dirt_hi"), c("wood_dk"))
        elif idx == 4:
            _icon_potion(d)
        elif idx == 5:
            _icon_pelt(d)
        elif idx == 6:
            _icon_coin(d)
        else:
            continue
        _outline_cell(cell)
        sheet.paste(cell, (idx * 32, 0), cell)
    return save(sheet, "items", "item_icons_sheet.png")


# --------------------------------------------------------------------------
# HUD bottom bar. hud.tscn slices ui_atlas.png at fixed regions:
#   left   (0,   0, 500, 145)
#   center (500, 0, 540, 145)
#   right  (1040,0, 380, 145)
# We repaint those exact regions as a cohesive pixel stone/wood panel so no
# scene edits are needed. HP/MP bars, quick slots and buttons overlay on top.
# --------------------------------------------------------------------------
def _bevel_panel(d, x0, y0, x1, y1, base, hi, lo, rim=None):
    d.rectangle([x0, y0, x1, y1], fill=base)
    d.line([(x0, y0), (x1, y0)], fill=hi)          # top light
    d.line([(x0, y0), (x0, y1)], fill=hi)          # left light
    d.line([(x0, y1), (x1, y1)], fill=lo)          # bottom shade
    d.line([(x1, y0), (x1, y1)], fill=lo)          # right shade
    if rim is not None:
        d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], outline=rim)


def _stud(d, x, y):
    d.ellipse([x - 2, y - 2, x + 2, y + 2], fill=c("gold"))
    d.point((x - 1, y - 1), fill=c("gold_hi"))


def build_hud_atlas():
    W, H = 1536, 160
    img = new_img(W, H)
    d = ImageDraw.Draw(img)
    rng = random.Random(4242)
    bar_w, bar_h = 1420, 145
    # base wood plank panel across the whole bar
    wood_dk, wood, wood_lt = c("wood_dk"), c("wood"), c("wood_lt")
    d.rectangle([0, 0, bar_w, bar_h], fill=wood)
    # plank texture (subtle horizontal grain)
    for y in range(0, bar_h, 3):
        for x in range(0, bar_w, 2):
            if rng.random() < 0.10:
                d.point((x, y), fill=wood_dk if rng.random() < 0.5 else wood_lt)
    # outer frame: dark border + gold rim
    d.rectangle([0, 0, bar_w - 1, bar_h - 1], outline=c("outline"))
    d.rectangle([3, 3, bar_w - 4, bar_h - 4], outline=c("gold"))
    d.line([(4, 4), (bar_w - 5, 4)], fill=c("gold_hi"))
    # region divider grooves at x=500 and x=1040
    for gx in (500, 1040):
        d.line([(gx, 6), (gx, bar_h - 7)], fill=c("wood_dk"))
        d.line([(gx + 1, 6), (gx + 1, bar_h - 7)], fill=wood_lt)
    # LEFT region: inset panels for HP/MP bars + two gem orbs
    _bevel_panel(d, 96, 34, 470, 66, c("bark_dk"), wood_lt, c("outline"))
    _bevel_panel(d, 96, 78, 470, 110, c("bark_dk"), wood_lt, c("outline"))
    # HP orb (red) and MP orb (blue) sockets on the far left
    for cx, cy, gdk, gmd, ghi in [(52, 52, (120, 24, 24), (196, 54, 48), (240, 140, 130)),
                                  (52, 96, (26, 52, 110), (54, 104, 190), (150, 190, 240))]:
        d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=c("outline"))
        d.ellipse([cx - 20, cy - 20, cx + 20, cy + 20], fill=gdk)
        d.ellipse([cx - 16, cy - 16, cx + 16, cy + 16], fill=gmd)
        d.ellipse([cx - 11, cy - 15, cx - 2, cy - 6], fill=ghi)
    # CENTER region: 6 quick-slot sockets
    slot_w = 62
    gap = (540 - 8 - 6 * slot_w) // 7
    for i in range(6):
        sx = 500 + gap + i * (slot_w + gap)
        _bevel_panel(d, sx, 40, sx + slot_w, 40 + slot_w, (26, 20, 16), wood_lt, c("outline"))
        _stud(d, sx + 4, 44)
    # RIGHT region: status plaque + two button sockets
    _bevel_panel(d, 1060, 20, 1404, 60, c("bark_dk"), wood_lt, c("outline"))
    for i in range(2):
        bx = 1080 + i * 170
        _bevel_panel(d, bx, 78, bx + 150, 122, (30, 22, 16), c("gold"), c("outline"))
    # corner studs
    for (sx, sy) in [(10, 10), (bar_w - 11, 10), (10, bar_h - 11), (bar_w - 11, bar_h - 11)]:
        _stud(d, sx, sy)
    return save(img, "ui", "ui_atlas.png")


# --------------------------------------------------------------------------
# Skill icons: 32px cells. icon_index in skills.json = column.
#   0 basic_slash  1 heavy_slash  2 fireball
# --------------------------------------------------------------------------
def _skill_basic_slash(d):
    # thin curved slash arc + small sword
    for i in range(20):
        t = i / 19.0
        x = int(7 + t * 18)
        y = int(24 - (t * 18) + 6 * (0.5 - abs(t - 0.5)) * 2)
        d.point((x, y), fill=c("steel_hi"))
        d.point((x, y + 1), fill=c("steel"))
    d.line([(8, 25), (16, 17)], fill=c("steel"))
    d.line([(7, 26), (9, 24)], fill=c("gold"))


def _skill_heavy_slash(d):
    # thick bright double slash arc
    for i in range(24):
        t = i / 23.0
        x = int(5 + t * 22)
        y = int(26 - (t * 20) + 7 * (0.5 - abs(t - 0.5)) * 2)
        d.rectangle([x, y, x + 1, y + 2], fill=(240, 210, 120, 255))
        d.point((x, y - 1), fill=(255, 240, 190, 255))
    for i in range(20):
        t = i / 19.0
        x = int(9 + t * 18)
        y = int(30 - (t * 18) + 5 * (0.5 - abs(t - 0.5)) * 2)
        d.point((x, y), fill=c("steel_hi"))


def _skill_fireball(d):
    d.ellipse([9, 12, 23, 26], fill=(220, 90, 40))
    d.ellipse([11, 14, 21, 24], fill=(240, 150, 50))
    d.ellipse([13, 16, 19, 22], fill=(250, 220, 120))
    # flame tongues upward
    for fx in (11, 15, 19):
        d.polygon([(fx, 12), (fx + 2, 5), (fx + 4, 12)], fill=(230, 120, 40))


def build_skill_icons():
    n = 6
    sheet = new_img(32 * n, 32)
    draws = [_skill_basic_slash, _skill_heavy_slash, _skill_fireball]
    for idx, fn in enumerate(draws):
        cell = new_img(32, 32)
        fn(ImageDraw.Draw(cell))
        _outline_cell(cell)
        sheet.paste(cell, (idx * 32, 0), cell)
    return save(sheet, "ui", "skill_icons_sheet.png")


if __name__ == "__main__":
    build_greenwood_village()
    build_black_wolf_forest()
    build_swordsman_atlas()
    build_swordsman_attack_atlas()
    build_npcs()
    build_wolf_sheet()
    build_wolf_boss_sheet()
    build_item_icons()
    build_hud_atlas()
    build_skill_icons()
