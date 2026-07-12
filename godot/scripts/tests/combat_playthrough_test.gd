extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const WolfScene := preload("res://scenes/actors/wild_wolf.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_main_scene_combat_playthrough(failures)

	if failures.is_empty():
		print("combat_playthrough_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_main_scene_combat_playthrough(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)

	var player := main.get_node_or_null("Player")
	var wolf := main.get_node_or_null("WildWolf")
	var hud := main.get_node_or_null("HUD")
	var hp_value := hud.find_child("HpValue", true, false) as Label if hud != null else null

	if wolf == null:
		wolf = WolfScene.instantiate()
		wolf.name = "WildWolf"
		main.add_child(wolf)

	if player == null:
		failures.append("main scene should include Player")
	if hp_value == null:
		failures.append("main scene should include HUD HP value")
	if player == null or wolf == null or hp_value == null:
		main.free()
		return

	await process_frame
	_assert_equal(hp_value.text, "100/100", "HUD should bind to player HP on scene start", failures)

	player.global_position = Vector2.ZERO
	wolf.global_position = player.global_position
	wolf.set_target(player)
	wolf._physics_process(0.016)
	_assert_equal(
		wolf.current_state,
		wolf.State.ATTACK,
		"nearby wild wolf should enter ATTACK state at distance %.2f" % wolf.global_position.distance_to(player.global_position),
		failures
	)

	player.facing_direction = Vector2.RIGHT
	var attack_started: bool = player.start_attack()
	_assert_equal(attack_started, true, "player should start attack from main scene", failures)
	var player_hitbox := player.get_node("AttackHitbox")
	var wolf_hurtbox := wolf.get_node("Hurtbox")
	var wolf_health := wolf.get_node("HealthComponent")
	var player_damage: int = wolf_hurtbox.receive_hit(player_hitbox)
	_assert_equal(player_damage, 11, "player hitbox should damage wolf through real main scene nodes", failures)
	_assert_equal(wolf_health.current_hp, 39, "wolf HP should decrease after player attack", failures)

	var wolf_hitbox := wolf.get_node("AttackHitbox")
	var player_hurtbox := player.get_node("Hurtbox")
	var player_health := player.get_node("HealthComponent")
	wolf_hitbox.setup(wolf, wolf.attack)
	var wolf_damage: int = player_hurtbox.receive_hit(wolf_hitbox)
	_assert_equal(wolf_damage, 3, "wolf hitbox should damage player through real main scene nodes", failures)
	_assert_equal(player_health.current_hp, 97, "player HP should decrease after wolf attack", failures)
	_assert_equal(hp_value.text, "97/100", "HUD should update after player takes damage", failures)

	for _i in range(4):
		wolf_hurtbox.receive_hit(player_hitbox)
		await process_frame

	_assert_equal(wolf_health.is_dead(), true, "player should be able to kill wolf in main scene", failures)
	_assert_equal(wolf.current_state, wolf.State.DEAD, "wolf should enter DEAD state in main scene", failures)

	main.free()


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
