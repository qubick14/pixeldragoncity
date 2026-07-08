extends SceneTree

const BLOCKOUT_PATH := "res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png"
const V2_PATH := "res://assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png"
const OUTPUT_PATH := "/tmp/pixeldragoncity_swordsman_walk_audit.png"

const SOURCE_COLUMNS := 4
const SOURCE_ROWS := 9
const OUTPUT_CELL := Vector2i(128, 128)
const GAP := 12
const SECTION_GAP := 48
const MARGIN := 24


func _initialize() -> void:
	var failures: Array[String] = []
	var blockout := _load_image(BLOCKOUT_PATH, failures)
	var v2 := _load_image(V2_PATH, failures)

	if not failures.is_empty():
		_report_failures(failures)
		return

	_validate_grid(blockout, BLOCKOUT_PATH, failures)
	_validate_grid(v2, V2_PATH, failures)

	if not failures.is_empty():
		_report_failures(failures)
		return

	var source_cell := Vector2i(
		int(blockout.get_width() / SOURCE_COLUMNS),
		int(blockout.get_height() / SOURCE_ROWS)
	)
	var section_width := SOURCE_COLUMNS * OUTPUT_CELL.x + (SOURCE_COLUMNS - 1) * GAP
	var canvas_size := Vector2i(
		MARGIN * 2 + section_width * 2 + SECTION_GAP,
		MARGIN * 2 + SOURCE_ROWS * OUTPUT_CELL.y + (SOURCE_ROWS - 1) * GAP
	)
	var canvas := Image.create(canvas_size.x, canvas_size.y, false, Image.FORMAT_RGBA8)
	canvas.fill(Color(0.045, 0.04, 0.035, 1.0))

	_blit_atlas(canvas, blockout, source_cell, Vector2i(MARGIN, MARGIN))
	_blit_atlas(canvas, v2, source_cell, Vector2i(MARGIN + section_width + SECTION_GAP, MARGIN))

	var save_error := canvas.save_png(OUTPUT_PATH)
	if save_error != OK:
		failures.append("failed to save swordsman walk audit image: %s" % error_string(save_error))

	if failures.is_empty():
		print("swordsman_walk_audit_image: PASS %s %sx%s" % [OUTPUT_PATH, canvas.get_width(), canvas.get_height()])
		quit(0)
		return

	_report_failures(failures)


func _load_image(path: String, failures: Array[String]) -> Image:
	var image := Image.new()
	var error := image.load(path)
	if error != OK:
		failures.append("failed to load %s: %s" % [path, error_string(error)])
	return image


func _validate_grid(image: Image, path: String, failures: Array[String]) -> void:
	if image.is_empty():
		failures.append("%s should not be empty" % path)
		return
	if image.get_width() % SOURCE_COLUMNS != 0:
		failures.append("%s width should divide by %d" % [path, SOURCE_COLUMNS])
	if image.get_height() % SOURCE_ROWS != 0:
		failures.append("%s height should divide by %d" % [path, SOURCE_ROWS])


func _blit_atlas(canvas: Image, atlas: Image, source_cell: Vector2i, origin: Vector2i) -> void:
	for row in range(SOURCE_ROWS):
		for column in range(SOURCE_COLUMNS):
			var source_rect := Rect2i(Vector2i(column, row) * source_cell, source_cell)
			var cell := atlas.get_region(source_rect)
			cell.resize(OUTPUT_CELL.x, OUTPUT_CELL.y, Image.INTERPOLATE_NEAREST)
			var target := origin + Vector2i(column * (OUTPUT_CELL.x + GAP), row * (OUTPUT_CELL.y + GAP))
			canvas.blit_rect(cell, Rect2i(Vector2i.ZERO, OUTPUT_CELL), target)


func _report_failures(failures: Array[String]) -> void:
	for failure in failures:
		push_error(failure)
	quit(1)
