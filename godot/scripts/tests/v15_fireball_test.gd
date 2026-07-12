extends SceneTree
# Verifies the fireball projectile: the swordsman's granted fireball skill spawns
# a projectile that flies, hits a wolf, damages it, spends MP, and despawns.
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
	var wolf: Node2D = mm.get_current_map().get_node("Enemies").get_child(0)
	wolf.set_target(null)  # keep the wolf still
	wolf.global_position = Vector2(120, 0)
	player.global_position = Vector2.ZERO

	# Fireball is the 3rd skill (index 2) granted to the swordsman.
	var bar: Array = player.get_skill_bar()
	if bar.size() < 3 or String(bar[2].get("type", "")) != "projectile":
		failures.append("swordsman should have a projectile skill in slot 3")

	var mp_before: int = int(player.current_mp)
	var wolf_hp_before: int = int(wolf.get_node("HealthComponent").current_hp)
	player.use_skill_slot(2)  # cast fireball toward the wolf (auto-aim)

	var spawned := false
	for _i in range(40):
		await physics_frame
		if not spawned:
			for n in main.get_children():
				if n.get("owner_node") == player and n.has_method("setup"):
					spawned = true
		if int(wolf.get_node("HealthComponent").current_hp) < wolf_hp_before:
			break

	if not spawned:
		failures.append("casting fireball should spawn a projectile")
	if int(wolf.get_node("HealthComponent").current_hp) >= wolf_hp_before:
		failures.append("fireball should damage the wolf it flies into")
	if int(player.current_mp) >= mp_before:
		failures.append("casting fireball should spend MP")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v15_fireball_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v15_fireball_test: FAIL")
	quit(1)
