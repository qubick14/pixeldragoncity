from __future__ import annotations

import argparse
from pathlib import Path

from PIL import Image


def remove_dark_background(source: Path, target: Path, threshold: int) -> None:
	image = Image.open(source).convert("RGBA")
	pixels = image.load()

	for y in range(image.height):
		for x in range(image.width):
			red, green, blue, alpha = pixels[x, y]
			if alpha > 0 and red <= threshold and green <= threshold and blue <= threshold:
				pixels[x, y] = (red, green, blue, 0)

	target.parent.mkdir(parents=True, exist_ok=True)
	image.save(target)


def main() -> None:
	parser = argparse.ArgumentParser(description="Convert near-black image backgrounds to transparent alpha.")
	parser.add_argument("source", type=Path)
	parser.add_argument("target", type=Path)
	parser.add_argument("--threshold", type=int, default=8)
	args = parser.parse_args()

	remove_dark_background(args.source, args.target, args.threshold)


if __name__ == "__main__":
	main()
