from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def find_components(image: Image.Image, min_area: int) -> list[tuple[int, int, int, int, int]]:
	alpha = image.getchannel("A")
	pixels = alpha.load()
	width, height = image.size
	seen: set[tuple[int, int]] = set()
	components: list[tuple[int, int, int, int, int]] = []

	for y in range(height):
		for x in range(width):
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
						if not (0 <= next_x < width and 0 <= next_y < height):
							continue
						if (next_x, next_y) in seen or pixels[next_x, next_y] == 0:
							continue
						seen.add((next_x, next_y))
						stack.append((next_x, next_y))

			if len(xs) >= min_area:
				components.append((len(xs), min(xs), min(ys), max(xs) + 1, max(ys) + 1))

	return components


def group_rows(components: list[tuple[int, int, int, int, int]], row_tolerance: int) -> list[list[tuple[int, int, int, int, int]]]:
	rows: list[list[tuple[int, int, int, int, int]]] = []

	for component in sorted(components, key=lambda item: (item[2], item[1])):
		_, _, top, _, _ = component
		for row in rows:
			row_top = min(item[2] for item in row)
			if abs(top - row_top) <= row_tolerance:
				row.append(component)
				break
		else:
			rows.append([component])

	for row in rows:
		row.sort(key=lambda item: item[1])

	return rows


def build_atlas(source: Path, target: Path, cell_size: int, columns: int, rows: int) -> None:
	image = Image.open(source).convert("RGBA")
	components = find_components(image, min_area=200)
	grouped_rows = group_rows(components, row_tolerance=36)

	atlas = Image.new("RGBA", (columns * cell_size, rows * cell_size), (0, 0, 0, 0))

	for row_index, row in enumerate(grouped_rows[:rows]):
		for column_index, component in enumerate(row[:columns]):
			_, left, top, right, bottom = component
			sprite = image.crop((left, top, right, bottom))
			target_x = column_index * cell_size + (cell_size - sprite.width) // 2
			target_y = row_index * cell_size + 164 - sprite.height
			atlas.alpha_composite(sprite, (target_x, target_y))

	target.parent.mkdir(parents=True, exist_ok=True)
	atlas.save(target)


def main() -> None:
	parser = argparse.ArgumentParser(description="Build a strict temporary atlas from the swordsman walk source.")
	parser.add_argument("source", type=Path)
	parser.add_argument("target", type=Path)
	parser.add_argument("--cell-size", type=int, default=192)
	parser.add_argument("--columns", type=int, default=4)
	parser.add_argument("--rows", type=int, default=7)
	args = parser.parse_args()

	build_atlas(args.source, args.target, args.cell_size, args.columns, args.rows)


if __name__ == "__main__":
	main()
