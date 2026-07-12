extends SceneTree
# Forest combat wiring + damage reliability (headless, runs physics):
#  - spawned wolves aggro the live player
#  - each player swing that overlaps a wolf deals damage (poll-based hitbox)
#  - a player's own swing never damages the player (owner exclusion)
#  - a wolf's attack damages the player
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
	var forest: Node = mm.get_current_map()
	var wolf: Node2D = forest.get_node("Enemies").get_child(0)
	var player_hc: Node = player.get_node("HealthComponent")
	var wolf_hc: Node = wolf.get_node("HealthComponent")

	if wolf.get("target") != player:
		failures.append("spawned wolf should target the player (aggro)")

	# Phase 1: player attacks the wolf with no retaliation (wolf disarmed).
	wolf.set_target(null)
	wolf.global_position = Vector2.ZERO
	player.global_position = Vector2(26, 0)
	player.set("facing_direction", Vector2.LEFT)
	var player_hp_start: int = int(player_hc.current_hp)

	var wolf_before: int = int(wolf_hc.current_hp)
	await _swing(player)
	var wolf_after_1: int = int(wolf_hc.current_hp)
	if wolf_after_1 >= wolf_before:
		failures.append("first swing should damage the wolf (%d -> %d)" % [wolf_before, wolf_after_1])

	# Wait out the basic-attack cooldown, then the second swing must also land
	# (reliability — not just the first area-enter event).
	for _i in range(40):
		await physics_frame
	await _swing(player)
	if int(wolf_hc.current_hp) >= wolf_after_1:
		failures.append("second swing should also damage the wolf (%d -> %d)" % [wolf_after_1, int(wolf_hc.current_hp)])

	if int(player_hc.current_hp) != player_hp_start:
		failures.append("player should not damage itself while swinging (%d -> %d)" % [player_hp_start, int(player_hc.current_hp)])

	# Phase 2: an aggroed wolf's bite damages the player.
	wolf.set_target(player)
	wolf.global_position = Vector2.ZERO
	player.global_position = Vector2(24, 0)
	var player_before: int = int(player_hc.current_hp)
	for _i in range(20):
		await physics_frame
	if int(player_hc.current_hp) >= player_before:
		failures.append("an adjacent aggroed wolf should damage the player (%d -> %d)" % [player_before, int(player_hc.current_hp)])

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v11_forest_combat_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v11_forest_combat_test: FAIL")
	quit(1)


func _swing(player: Node) -> void:
	player.start_attack()
	for _i in range(12):
		await physics_frame
