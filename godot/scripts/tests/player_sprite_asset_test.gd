extends SceneTree

const PlayerScene := preload("res://scenes/actors/player.tscn")
const EXPECTED_TEXTURE_PATH := "res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png"


func _initialize() -> void:
	var failures: Array[String] = []
	var player := PlayerScene.instantiate()
	root.add_child(player)

	var sprite := player.get_node("VisualRoot/GeneratedSprite") as Sprite2D
	_assert_equal(sprite.texture.resource_path, EXPECTED_TEXTURE_PATH, "player should use the deterministic swordsman blockout atlas", failures)
	_assert_equal(player.walk_atlas_columns, 4, "walk atlas should use 4 columns", failures)
	_assert_equal(player.walk_atlas_rows, 9, "walk atlas should use 9 rows", failures)
	_assert_equal(player.get_test_atlas_row(Vector2i(0, 1)), 2, "left movement should use the left-facing row", failures)
	_assert_equal(player.get_test_atlas_row(Vector2i(2, 1)), 6, "right movement should use the right-facing row", failures)
	_assert_equal(player.should_flip_test_atlas_row(Vector2i(0, 1)), false, "blockout left row should not be mirrored", failures)
	_assert_equal(player.should_flip_test_atlas_row(Vector2i(2, 1)), false, "blockout right row should not be mirrored", failures)

	player.queue_free()

	if failures.is_empty():
		print("player_sprite_asset_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
