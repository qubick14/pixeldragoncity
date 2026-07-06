from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw


CELL = 96
SCALE = 2
COLUMNS = 4
ROWS = 9


COLORS = {
	"outline": (20, 16, 14, 255),
	"skin": (196, 132, 82, 255),
	"hair": (76, 42, 24, 255),
	"armor": (82, 84, 88, 255),
	"armor_light": (160, 162, 152, 255),
	"leather": (88, 50, 32, 255),
	"cloth": (128, 28, 28, 255),
	"cloth_dark": (78, 18, 24, 255),
	"boot": (38, 30, 26, 255),
	"blade": (190, 210, 210, 255),
	"blade_dark": (88, 112, 120, 255),
	"gold": (178, 126, 40, 255),
}


ROW_DIRECTIONS = [
	"down",
	"down_left",
	"left",
	"up_left",
	"up",
	"up_right",
	"right",
	"down_right",
	"idle_front",
]


def rect(draw: ImageDraw.ImageDraw, xy: tuple[int, int, int, int], color: str) -> None:
	draw.rectangle(xy, fill=COLORS[color])


def poly(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: str) -> None:
	draw.polygon(points, fill=COLORS[color])


def line(draw: ImageDraw.ImageDraw, points: list[tuple[int, int]], color: str, width: int = 2) -> None:
	draw.line(points, fill=COLORS[color], width=width)


def draw_front(draw: ImageDraw.ImageDraw, frame: int, back: bool = False) -> None:
	base_y = 78
	left_leg_shift = [-3, -5, -2, 1][frame]
	right_leg_shift = [3, 1, 5, 2][frame]
	body_bob = [0, -1, 0, -1][frame]

	if back:
		poly(draw, [(36, 33), (60, 33), (66, 70), (58, 80), (38, 80), (30, 70)], "cloth")
	else:
		poly(draw, [(34, 34), (62, 34), (57, 66), (39, 66)], "leather")
		rect(draw, (38, 42, 58, 55), "armor")

	rect(draw, (39 + left_leg_shift, 61, 46 + left_leg_shift, base_y), "boot")
	rect(draw, (50 + right_leg_shift, 61, 57 + right_leg_shift, base_y), "boot")
	rect(draw, (37 + left_leg_shift, base_y - 4, 47 + left_leg_shift, base_y), "boot")
	rect(draw, (49 + right_leg_shift, base_y - 4, 59 + right_leg_shift, base_y), "boot")

	if back:
		rect(draw, (40, 20 + body_bob, 56, 34 + body_bob), "hair")
		rect(draw, (36, 30 + body_bob, 60, 39 + body_bob), "cloth_dark")
	else:
		rect(draw, (40, 18 + body_bob, 56, 34 + body_bob), "skin")
		rect(draw, (38, 15 + body_bob, 58, 23 + body_bob), "hair")
		rect(draw, (37, 31 + body_bob, 59, 38 + body_bob), "cloth")

	rect(draw, (28, 35 + body_bob, 37, 50 + body_bob), "armor")
	rect(draw, (59, 35 + body_bob, 68, 50 + body_bob), "armor")
	line(draw, [(30, 52), (23, 74)], "blade", 3)
	line(draw, [(28, 52), (35, 48)], "gold", 2)


def draw_side(draw: ImageDraw.ImageDraw, frame: int, direction: int, diagonal_y: int = 0, back_bias: bool = False) -> None:
	base_y = 78
	front_leg = [-6, -10, -3, 4][frame]
	back_leg = [5, 1, 9, 3][frame]
	body_bob = [0, -1, 0, -1][frame]
	facing_left = direction < 0

	def sx(value: int) -> int:
		return 96 - value if facing_left else value

	cape_back = sx(64 if not facing_left else 32)
	body_x = 48
	head_x = 47

	poly(draw, [(sx(38), 36 + diagonal_y), (sx(64), 43 + diagonal_y), (sx(66), 64 + diagonal_y), (sx(42), 62 + diagonal_y)], "cloth")
	poly(draw, [(sx(34), 34 + body_bob), (sx(58), 33 + body_bob), (sx(61), 62), (sx(37), 64)], "leather")
	rect(draw, (min(sx(39), sx(58)), 42 + body_bob, max(sx(39), sx(58)), 55 + body_bob), "armor")
	rect(draw, (min(sx(43), sx(56)), 18 + body_bob, max(sx(43), sx(56)), 34 + body_bob), "skin")
	rect(draw, (min(sx(39), sx(58)), 15 + body_bob, max(sx(39), sx(58)), 24 + body_bob), "hair")
	rect(draw, (min(sx(37), sx(59)), 31 + body_bob, max(sx(37), sx(59)), 38 + body_bob), "cloth")

	rect(draw, (min(sx(41), sx(48)) + front_leg * direction, 60, max(sx(41), sx(48)) + front_leg * direction, base_y), "boot")
	rect(draw, (min(sx(50), sx(57)) + back_leg * direction, 60, max(sx(50), sx(57)) + back_leg * direction, base_y), "boot")
	rect(draw, (min(sx(39), sx(50)) + front_leg * direction, base_y - 4, max(sx(39), sx(50)) + front_leg * direction, base_y), "boot")
	rect(draw, (min(sx(48), sx(59)) + back_leg * direction, base_y - 4, max(sx(48), sx(59)) + back_leg * direction, base_y), "boot")

	sword_tip_x = sx(22 if facing_left else 74)
	sword_hand_x = sx(42 if facing_left else 54)
	line(draw, [(sword_hand_x, 52 + diagonal_y), (sword_tip_x, 76 + diagonal_y)], "blade", 3)
	line(draw, [(sword_hand_x - direction * 5, 51 + diagonal_y), (sword_hand_x + direction * 5, 47 + diagonal_y)], "gold", 2)


def draw_side_right(draw: ImageDraw.ImageDraw, frame: int, diagonal_y: int = 0) -> None:
	base_y = 78
	front_leg = [-6, -10, -3, 4][frame]
	back_leg = [5, 1, 9, 3][frame]
	body_bob = [0, -1, 0, -1][frame]

	poly(draw, [(34, 36 + diagonal_y), (62, 43 + diagonal_y), (66, 64 + diagonal_y), (38, 62 + diagonal_y)], "cloth")
	poly(draw, [(38, 34 + body_bob), (62, 33 + body_bob), (61, 62), (37, 64)], "leather")
	rect(draw, (39, 42 + body_bob, 58, 55 + body_bob), "armor")
	rect(draw, (43, 18 + body_bob, 56, 34 + body_bob), "skin")
	rect(draw, (39, 15 + body_bob, 58, 24 + body_bob), "hair")
	rect(draw, (37, 31 + body_bob, 59, 38 + body_bob), "cloth")

	rect(draw, (41 + front_leg, 60, 48 + front_leg, base_y), "boot")
	rect(draw, (50 + back_leg, 60, 57 + back_leg, base_y), "boot")
	rect(draw, (39 + front_leg, base_y - 4, 50 + front_leg, base_y), "boot")
	rect(draw, (48 + back_leg, base_y - 4, 59 + back_leg, base_y), "boot")

	line(draw, [(54, 52 + diagonal_y), (74, 76 + diagonal_y)], "blade", 3)
	line(draw, [(49, 51 + diagonal_y), (59, 47 + diagonal_y)], "gold", 2)


def paste_side(image: Image.Image, frame: int, facing_left: bool, diagonal_y: int = 0) -> None:
	side = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	draw_side_right(ImageDraw.Draw(side), frame, diagonal_y)
	if facing_left:
		side = side.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
	image.alpha_composite(side)


def draw_cell(direction: str, frame: int) -> Image.Image:
	image = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
	draw = ImageDraw.Draw(image)

	if direction in ("down", "idle_front"):
		draw_front(draw, frame if direction == "down" else 0, back=False)
	elif direction == "up":
		draw_front(draw, frame, back=True)
	elif direction == "left":
		paste_side(image, frame, True)
	elif direction == "right":
		paste_side(image, frame, False)
	elif direction == "down_left":
		paste_side(image, frame, True, diagonal_y=2)
	elif direction == "down_right":
		paste_side(image, frame, False, diagonal_y=2)
	elif direction == "up_left":
		paste_side(image, frame, True, diagonal_y=-5)
	elif direction == "up_right":
		paste_side(image, frame, False, diagonal_y=-5)

	return image.resize((CELL * SCALE, CELL * SCALE), Image.Resampling.NEAREST)


def build_atlas(target: Path) -> None:
	atlas = Image.new("RGBA", (COLUMNS * CELL * SCALE, ROWS * CELL * SCALE), (0, 0, 0, 0))

	for row, direction in enumerate(ROW_DIRECTIONS):
		for column in range(COLUMNS):
			atlas.alpha_composite(draw_cell(direction, column), (column * CELL * SCALE, row * CELL * SCALE))

	target.parent.mkdir(parents=True, exist_ok=True)
	atlas.save(target)


if __name__ == "__main__":
	build_atlas(Path("assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png"))
	build_atlas(Path("godot/assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png"))
