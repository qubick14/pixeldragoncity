extends SceneTree
# Verifies the blackstone mine is populated: cave slimes spawn, aggro the player,
# and killing one grants exp/gold (uses the shared monster data + reward path).
const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame
	var mm := main.get_node_or_null("MapManager")
	mm.load_map("blackstone_mine", "mine_entry")
	for _i in range(4):
		await process_frame

	var enemies: Node = mm.get_current_map().get_node("Enemies")
	if enemies.get_child_count() < 3:
		failures.append("mine should contain cave slimes, got %d enemies" % enemies.get_child_count())

	var player: Node2D = main.get_node_or_null("Player")
	var slime: Node = enemies.get_child(0)
	if String(slime.get("monster_id")) != "cave_slime":
		failures.append("mine enemy should be a cave_slime, got %s" % str(slime.get("monster_id")))
	if slime.get("target") != player:
		failures.append("mine slime should aggro the player")

	var exp_before: int = main._player_exp
	var lvl_before: int = main._player_level
	slime.get_node("HealthComponent").apply_damage(99999, null)
	for _i in range(3):
		await process_frame
	if main._player_exp <= exp_before and main._player_level <= lvl_before:
		failures.append("killing a cave slime should grant EXP")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v16_mine_content_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v16_mine_content_test: FAIL")
	quit(1)
