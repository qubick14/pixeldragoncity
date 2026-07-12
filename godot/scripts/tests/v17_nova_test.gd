extends SceneTree
# Verifies the spirit-nova AoE skill: one cast damages every enemy within its
# radius (and spends MP), while enemies outside the radius are untouched.
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
	player.global_position = Vector2.ZERO
	var enemies: Node = mm.get_current_map().get_node("Enemies")
	var near_a: Node = enemies.get_child(0)
	var near_b: Node = enemies.get_child(1)
	var far: Node = enemies.get_child(2)
	for e in [near_a, near_b, far]:
		e.set_target(null)
	near_a.global_position = Vector2(60, 0)
	near_b.global_position = Vector2(-50, 40)
	far.global_position = Vector2(600, 0)

	var hp_a: int = int(near_a.get_node("HealthComponent").current_hp)
	var hp_b: int = int(near_b.get_node("HealthComponent").current_hp)
	var hp_far: int = int(far.get_node("HealthComponent").current_hp)
	var mp_before: int = int(player.current_mp)

	player.use_skill_slot(3)  # spirit nova (U)
	await process_frame

	if int(near_a.get_node("HealthComponent").current_hp) >= hp_a:
		failures.append("nova should damage enemy A in radius")
	if int(near_b.get_node("HealthComponent").current_hp) >= hp_b:
		failures.append("nova should damage enemy B in radius")
	if int(far.get_node("HealthComponent").current_hp) != hp_far:
		failures.append("nova should NOT damage the far enemy")
	if int(player.current_mp) >= mp_before:
		failures.append("nova should spend MP")

	main.queue_free()
	await process_frame
	if failures.is_empty():
		print("v17_nova_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v17_nova_test: FAIL")
	quit(1)
