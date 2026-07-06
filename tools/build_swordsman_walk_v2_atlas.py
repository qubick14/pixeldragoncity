from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_green_key(image: Image.Image) -> Image.Image:
	output = image.convert("RGBA")
	pixels = output.load()

	for y in range(output.height):
		for x in range(output.width):
			red, green, blue, alpha = pixels[x, y]
			if alpha > 0 and green > 75 and green > red * 1.18 and green > blue * 1.18:
				pixels[x, y] = (red, green, blue, 0)
			elif alpha > 0 and green > red and green > blue:
				pixels[x, y] = (red, max(red, blue), blue, alpha)

	return output


def find_components(image: Image.Image, min_area: int) -> list[tuple[int, int, int, int, int]]:
	alpha = image.getchannel("A")
	pixels = alpha.load()
	seen: set[tuple[int, int]] = set()
	components: list[tuple[int, int, int, int, int]] = []

	for y in range(image.height):
		for x in range(image.width):
			if pixels[x, y] == 0 or (x, y) in seen:
				continue

			stack = [(x, y)]
			seen.add((x, y))
			xs: list[int] = []
			ys: list[int] = []

			while stack:
				current_x, current_y = stack.pop()
				xs.append(current_x)
				ys.append(current_y)

				for next_y in range(current_y - 1, current_y + 2):
					for next_x in range(current_x - 1, current_x + 2):
						if not (0 <= next_x < image.width and 0 <= next_y < image.height):
							continue
						if (next_x, next_y) in seen or pixels[next_x, next_y] == 0:
							continue
						seen.add((next_x, next_y))
						stack.append((next_x, next_y))

			if len(xs) >= min_area:
				components.append((len(xs), min(xs), min(ys), max(xs) + 1, max(ys) + 1))

	return components


def group_rows(components: list[tuple[int, int, int, int, int]]) -> list[list[tuple[int, int, int, int, int]]]:
	rows: list[list[tuple[int, int, int, int, int]]] = []

	for component in sorted(components, key=lambda item: (item[2], item[1])):
		_, _, top, _, bottom = component
		center_y = (top + bottom) / 2.0
		for row in rows:
			row_center_y = sum((item[2] + item[4]) / 2.0 for item in row) / len(row)
			if abs(center_y - row_center_y) < 90:
				row.append(component)
				break
		else:
			rows.append([component])

	for row in rows:
		row.sort(key=lambda item: item[1])

	return rows


def alpha_bounds(image: Image.Image) -> tuple[int, int, int, int]:
	alpha = image.getchannel("A")
	bounds = alpha.getbbox()
	if bounds == None:
		return (0, 0, image.width, image.height)
	return bounds


def paste_centered(atlas: Image.Image, sprite: Image.Image, column: int, row: int, cell_size: int) -> None:
	bounds = alpha_bounds(sprite)
	sprite = sprite.crop(bounds)

	max_width = int(cell_size * 0.88)
	max_height = int(cell_size * 0.86)
	scale = min(max_width / sprite.width, max_height / sprite.height, 1.0)
	if scale < 1.0:
		sprite = sprite.resize((int(sprite.width * scale), int(sprite.height * scale)), Image.Resampling.LANCZOS)

	target_x = column * cell_size + (cell_size - sprite.width) // 2
	target_y = row * cell_size + int(cell_size * 0.88) - sprite.height
	atlas.alpha_composite(sprite, (target_x, target_y))


def build_atlas(source: Path, target: Path, cell_size: int) -> None:
	source_image = remove_green_key(Image.open(source))
	source_columns = 4
	target_rows = 9

	atlas = Image.new("RGBA", (source_columns * cell_size, target_rows * cell_size), (0, 0, 0, 0))
	rows = group_rows(find_components(source_image, min_area=600))

	for source_row, row in enumerate(rows[:8]):
		for column, component in enumerate(row[:source_columns]):
			_, left, top, right, bottom = component
			padding = 8
			left = max(0, left - padding)
			top = max(0, top - padding)
			right = min(source_image.width, right + padding)
			bottom = min(source_image.height, bottom + padding)
			sprite = source_image.crop((left, top, right, bottom))
			paste_centered(atlas, sprite, column, source_row, cell_size)

	for column in range(source_columns):
		front_idle = atlas.crop((column * cell_size, 0, (column + 1) * cell_size, cell_size))
		atlas.alpha_composite(front_idle, (column * cell_size, 8 * cell_size))

	target.parent.mkdir(parents=True, exist_ok=True)
	atlas.save(target)


def main() -> None:
	parser = argparse.ArgumentParser(description="Build a strict 4x9 swordsman walk atlas from the v2 generated source.")
	parser.add_argument("source", type=Path)
	parser.add_argument("target", type=Path)
	parser.add_argument("--cell-size", type=int, default=192)
	args = parser.parse_args()

	build_atlas(args.source, args.target, args.cell_size)


if __name__ == "__main__":
	main()
