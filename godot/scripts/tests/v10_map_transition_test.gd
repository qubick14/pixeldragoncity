extends SceneTree
# Verifies the in-game map transition trigger wired in main.gd: standing on the
# village -> forest transition point and pressing interact (E) loads the forest.
# Headless.
const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame

	var map_manager := main.get_node_or_null("MapManager")
	var player := main.get_node_or_null("Player")
	if map_manager == null or player == null:
		_fail(failures, "main should expose MapManager and Player")
		_finish(main, failures)
		return

	if map_manager.current_map_id != "greenwood_village":
		_fail(failures, "should start in greenwood_village, got %s" % map_manager.current_map_id)

	# Stand on the transition marker and clear the post-load cooldown.
	var marker: Node = map_manager.get_current_map().get_node_or_null("TransitionPoints/ToBlackWolfForest")
	if marker == null:
		_fail(failures, "village should have ToBlackWolfForest transition marker")
	else:
		player.global_position = marker.global_position
		main._transition_cooldown = 0.0
		main._on_player_interact_requested()
		await process_frame
		if map_manager.current_map_id != "black_wolf_forest":
			_fail(failures, "pressing E on the transition should load black_wolf_forest, got %s" % map_manager.current_map_id)

	_finish(main, failures)


func _finish(main: Node, failures: Array[String]) -> void:
	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v10_map_transition_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v10_map_transition_test: FAIL")
	quit(1)


func _fail(failures: Array[String], message: String) -> void:
	failures.append(message)
