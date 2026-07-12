extends SceneTree
# Verifies kill rewards (exp + gold) and the extended map flow: forest -> mine,
# and mine -> forest returning to the interface (mine-gate) spawn, not the origin.
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
	var player: Node2D = main.get_node_or_null("Player")

	# --- Kill reward: exp + gold from a wolf death ---------------------------
	var wolf: Node = mm.get_current_map().get_node("Enemies").get_child(0)
	var exp_before: int = main._player_exp
	var gold_before: int = main._inventory.gold
	wolf.get_node("HealthComponent").apply_damage(99999, null)
	for _i in range(3):
		await process_frame
	if main._player_exp <= exp_before and main._player_level <= 1:
		failures.append("killing a wolf should grant EXP")
	if main._inventory.gold <= gold_before:
		failures.append("killing a wolf should grant gold")

	# --- Forest -> Blackstone Mine ------------------------------------------
	_e_at(main, player, "TransitionPoints/ToBlackstoneMine")
	await process_frame
	if mm.current_map_id != "blackstone_mine":
		failures.append("E at the mine gate should load blackstone_mine, got %s" % mm.current_map_id)
	else:
		var entry: Node2D = mm.get_current_map().get_node("SpawnPoints/MineEntry")
		if player.global_position.distance_to(entry.global_position) > 1.0:
			failures.append("entering the mine should place the player at MineEntry")

	# --- Mine -> Forest returns to the interface (mine-gate) spawn -----------
	_e_at(main, player, "TransitionPoints/ToBlackWolfForest")
	await process_frame
	if mm.current_map_id != "black_wolf_forest":
		failures.append("E at the mine's forest gate should return to the forest, got %s" % mm.current_map_id)
	else:
		var gate: Node2D = mm.get_current_map().get_node("SpawnPoints/ForestMineGate")
		if player.global_position.distance_to(gate.global_position) > 1.0:
			failures.append("returning to the forest should spawn at ForestMineGate (interface), not the origin")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v14_progression_map_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v14_progression_map_test: FAIL")
	quit(1)


func _e_at(main: Node, player: Node2D, marker_path: String) -> void:
	# Stand on a transition marker, clear the post-load cooldown, press interact.
	var mm := main.get_node_or_null("MapManager")
	var marker: Node2D = mm.get_current_map().get_node(marker_path)
	player.global_position = marker.global_position
	main._transition_cooldown = 0.0
	main._on_player_interact_requested()
