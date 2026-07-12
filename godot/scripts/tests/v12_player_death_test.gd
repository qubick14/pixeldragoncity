extends SceneTree
# Verifies player death handling: lethal damage in the forest respawns the player
# in the village at full HP (with the death flash overlay played). Headless.
const MainScene := preload("res://scenes/main.tscn")


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
	if mm.current_map_id != "black_wolf_forest":
		failures.append("precondition: should be in the forest")

	var player: Node = main.get_node_or_null("Player")
	var hc: Node = player.get_node("HealthComponent")
	hc.apply_damage(99999, null)  # lethal
	for _i in range(6):
		await process_frame

	if mm.current_map_id != "greenwood_village":
		failures.append("death should return the player to greenwood_village, got %s" % mm.current_map_id)
	if int(hc.current_hp) != int(hc.max_hp):
		failures.append("death should restore full HP (%d/%d)" % [int(hc.current_hp), int(hc.max_hp)])
	if hc.is_dead():
		failures.append("player should be alive after respawn")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v12_player_death_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v12_player_death_test: FAIL")
	quit(1)
