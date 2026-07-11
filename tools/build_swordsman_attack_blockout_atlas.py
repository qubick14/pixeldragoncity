from __future__ import annotations

import math
from pathlib import Path

from PIL import Image, ImageDraw


SOURCE_CELL = 192
WORK_CELL = 96
OUTPUT_CELL = 192
COLUMNS = 6
ROWS = 9

SOURCE_PATH = Path("assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png")
TARGET_PATHS = (
	Path("assets/sprites/swordsman/swordsman_attack_blockout_v1_atlas.png"),
	Path("godot/assets/sprites/swordsman/swordsman_attack_blockout_v1_atlas.png"),
)

ROW_ANGLES = (90, 135, 180, 225, 270, 315, 0, 45, 90)
SWING_OFFSETS = (-70, -45, -10, 20, 45, 70)
SWORD_LENGTHS = (24, 29, 38, 44, 38, 27)
LUNGE_PIXELS = (0, 1, 3, 5, 3, 0)

OUTLINE = (20, 16, 14, 255)
BLADE_DARK = (88, 112, 120, 255)
BLADE = (205, 222, 220, 255)
GOLD = (178, 126, 40, 255)
SLASH = (242, 220, 150, 150)
SOURCE_WEAPON_COLORS = {
	(190, 210, 210, 255),
	BLADE_DARK,
	GOLD,
}


def point(origin: tuple[float, float], angle: float, distance: float) -> tuple[int, int]:
	radians = math.radians(angle)
	return (
		round(origin[0] + math.cos(radians) * distance),
		round(origin[1] + math.sin(radians) * distance),
	)


def remove_source_weapon(base: Image.Image) -> Image.Image:
	cleaned = base.copy()
	pixels = cleaned.load()
	for y in range(cleaned.height):
		for x in range(cleaned.width):
			if pixels[x, y] in SOURCE_WEAPON_COLORS:
				pixels[x, y] = (0, 0, 0, 0)
	return cleaned


def build_frame(base: Image.Image, row: int, frame: int) -> Image.Image:
	angle = ROW_ANGLES[row]
	direction_angle = math.radians(angle)
	lunge = LUNGE_PIXELS[frame]
	offset = (
		round(math.cos(direction_angle) * lunge),
		round(math.sin(direction_angle) * lunge * 0.55),
	)

	canvas = Image.new("RGBA", (WORK_CELL, WORK_CELL), (0, 0, 0, 0))
	canvas.alpha_composite(base, offset)
	draw = ImageDraw.Draw(canvas, "RGBA")

	hand = (48 + offset[0], 49 + offset[1])
	sword_angle = angle + SWING_OFFSETS[frame]
	guard_left = point(hand, sword_angle - 90, 5)
	guard_right = point(hand, sword_angle + 90, 5)
	blade_start = point(hand, sword_angle, 4)
	blade_end = point(hand, sword_angle, SWORD_LENGTHS[frame])

	if frame in (2, 3, 4):
		arc_start = angle + SWING_OFFSETS[max(0, frame - 1)]
		arc_end = angle + SWING_OFFSETS[frame]
		arc_box = (hand[0] - 47, hand[1] - 47, hand[0] + 47, hand[1] + 47)
		draw.arc(arc_box, start=arc_start, end=arc_end, fill=SLASH, width=3)

	draw.line((blade_start, blade_end), fill=OUTLINE, width=6)
	draw.line((blade_start, blade_end), fill=BLADE_DARK, width=4)
	draw.line((blade_start, blade_end), fill=BLADE, width=2)
	draw.line((guard_left, guard_right), fill=OUTLINE, width=4)
	draw.line((guard_left, guard_right), fill=GOLD, width=2)
	draw.ellipse((hand[0] - 2, hand[1] - 2, hand[0] + 2, hand[1] + 2), fill=GOLD)

	return canvas.resize((OUTPUT_CELL, OUTPUT_CELL), Image.Resampling.NEAREST)


def build_atlas(source_path: Path, target_paths: tuple[Path, ...]) -> None:
	source = Image.open(source_path).convert("RGBA")
	if source.size != (SOURCE_CELL * 4, SOURCE_CELL * ROWS):
		raise ValueError(f"unexpected walk atlas size: {source.size}")

	atlas = Image.new("RGBA", (OUTPUT_CELL * COLUMNS, OUTPUT_CELL * ROWS), (0, 0, 0, 0))
	for row in range(ROWS):
		base = source.crop((0, row * SOURCE_CELL, SOURCE_CELL, (row + 1) * SOURCE_CELL))
		base = base.resize((WORK_CELL, WORK_CELL), Image.Resampling.NEAREST)
		base = remove_source_weapon(base)
		for frame in range(COLUMNS):
			atlas.alpha_composite(build_frame(base, row, frame), (frame * OUTPUT_CELL, row * OUTPUT_CELL))

	for target_path in target_paths:
		target_path.parent.mkdir(parents=True, exist_ok=True)
		atlas.save(target_path)


if __name__ == "__main__":
	build_atlas(SOURCE_PATH, TARGET_PATHS)
