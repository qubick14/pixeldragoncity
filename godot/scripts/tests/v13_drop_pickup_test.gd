extends SceneTree
# Verifies E-key pickup of nearby dropped items (auto walk-over pickup still works
# via the body layer too, but E-pickup is the deterministic path we assert here).
const MainScene := preload("res://scenes/main.tscn")
const DroppedItemScene := preload("res://scenes/loot/dropped_item.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame
	var mm := main.get_node_or_null("MapManager")
	mm.load_map("black_wolf_forest", "forest_entry")
	for _i in range(4):
		await process_frame

	var player: Node2D = main.get_node_or_null("Player")
	var drop: Node2D = DroppedItemScene.instantiate()
	mm.get_current_map().add_child(drop)
	drop.setup_item("wolf_pelt", 1)
	drop.global_position = player.global_position + Vector2(28, 0)
	await process_frame

	var before: int = main._inventory.count_item("wolf_pelt")
	# Post-load transition cooldown is active, so E resolves to item pickup here.
	main._on_player_interact_requested()
	await process_frame

	if main._inventory.count_item("wolf_pelt") != before + 1:
		failures.append("pressing E next to a drop should add it to the inventory")
	if is_instance_valid(drop) and not drop.is_queued_for_deletion():
		failures.append("collected drop should be freed")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v13_drop_pickup_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v13_drop_pickup_test: FAIL")
	quit(1)
