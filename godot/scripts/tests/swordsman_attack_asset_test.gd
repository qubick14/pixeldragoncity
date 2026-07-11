extends SceneTree

const ATTACK_ATLAS_PATH := "res://assets/sprites/swordsman/swordsman_attack_blockout_v1_atlas.png"
const COLUMNS := 6
const ROWS := 9
const CELL_SIZE := Vector2i(192, 192)


func _initialize() -> void:
	var failures: Array[String] = []
	var image := Image.new()
	var load_error := image.load(ATTACK_ATLAS_PATH)

	if load_error != OK:
		failures.append("attack atlas should load: %s" % error_string(load_error))
	else:
		_assert_equal(
			Vector2i(image.get_width(), image.get_height()),
			Vector2i(COLUMNS * CELL_SIZE.x, ROWS * CELL_SIZE.y),
			"attack atlas should use a strict 6x9 grid of 192x192 cells",
			failures
		)
		_assert_equal(image.get_format(), Image.FORMAT_RGBA8, "attack atlas should use RGBA8", failures)
		_assert_equal(image.detect_alpha(), Image.ALPHA_BLEND, "attack atlas should preserve transparency", failures)
		_assert_each_frame_has_visible_pixels(image, failures)

	if failures.is_empty():
		print("swordsman_attack_asset_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _assert_each_frame_has_visible_pixels(image: Image, failures: Array[String]) -> void:
	for row in range(ROWS):
		for column in range(COLUMNS):
			var frame := image.get_region(Rect2i(Vector2i(column, row) * CELL_SIZE, CELL_SIZE))
			if frame.get_used_rect().size == Vector2i.ZERO:
				failures.append("attack frame row %d column %d should contain visible pixels" % [row, column])


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
