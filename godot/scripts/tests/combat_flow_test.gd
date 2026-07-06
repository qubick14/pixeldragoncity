extends SceneTree

const PlayerScene := preload("res://scenes/actors/player.tscn")
const WolfScene := preload("res://scenes/actors/wild_wolf.tscn")
const WOLF_SCENE_PATH := "res://scenes/actors/wild_wolf.tscn"
const DAMAGE_NUMBER_PATH := "res://scripts/combat/damage_number.gd"


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_wild_wolf_combat_flow(failures)
	await _test_wild_wolf_spawns_loot_on_death(failures)

	if failures.is_empty():
		print("combat_flow_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_wild_wolf_combat_flow(failures: Array[String]) -> void:
	var wolf_scene := load(WOLF_SCENE_PATH) as PackedScene
	if wolf_scene == null:
		failures.append("wild wolf scene should load from %s" % WOLF_SCENE_PATH)
		return

	var player := PlayerScene.instantiate()
	root.add_child(player)
	player.global_position = Vector2.ZERO

	var wolf := wolf_scene.instantiate()
	root.add_child(wolf)
	wolf.global_position = Vector2(100, 0)
	wolf.set_target(player)

	var wolf_health := wolf.get_node("HealthComponent")
	_assert_equal(wolf_health.max_hp, 50, "wild wolf should start with 50 max HP", failures)
	_assert_equal(wolf_health.current_hp, 50, "wild wolf should start alive at full HP", failures)
	_assert_equal(player.has_node("HealthBar"), true, "player should have a world HealthBar", failures)
	_assert_equal(wolf.has_node("HealthBar"), true, "wild wolf should have a world HealthBar", failures)

	wolf._physics_process(0.1)
	_assert_equal(wolf.current_state, wolf.State.CHASE, "wild wolf should chase nearby player", failures)

	var player_attack := player.get_node("AttackHitbox")
	player_attack.setup(player, 12)
	var damage: int = wolf.get_node("Hurtbox").receive_hit(player_attack)
	_assert_equal(damage, 11, "player attack should damage wild wolf after defense", failures)
	_assert_equal(wolf_health.current_hp, 39, "wild wolf HP should drop after player hit", failures)
	if wolf.has_node("HealthBar"):
		_assert_equal(wolf.get_node("HealthBar").current_hp, 39, "wild wolf health bar should update after damage", failures)

	for _i in range(4):
		wolf.get_node("Hurtbox").receive_hit(player_attack)

	_assert_equal(wolf_health.is_dead(), true, "repeated player attacks should kill the wild wolf", failures)
	_assert_equal(wolf.current_state, wolf.State.DEAD, "dead wild wolf should enter DEAD state", failures)
	_assert_equal(wolf.get_node("AttackHitbox").enabled, false, "dead wild wolf should disable attack hitbox", failures)
	_assert_equal(wolf.get_node("CollisionShape2D").disabled, true, "dead wild wolf should disable body collision", failures)

	await _test_damage_number(failures)

	player.free()
	wolf.free()


func _test_wild_wolf_spawns_loot_on_death(failures: Array[String]) -> void:
	var parent := Node2D.new()
	root.add_child(parent)

	var player := PlayerScene.instantiate()
	parent.add_child(player)

	var wolf := WolfScene.instantiate()
	parent.add_child(wolf)
	wolf.set_target(player)

	var player_attack := player.get_node("AttackHitbox")
	player_attack.setup(player, 20)
	for _i in range(3):
		wolf.get_node("Hurtbox").receive_hit(player_attack)

	_assert_equal(wolf.get_node("HealthComponent").is_dead(), true, "test wolf should be dead before checking loot", failures)
	_assert_equal(_count_dropped_items(parent) > 0, true, "wild wolf should spawn dropped items when it dies", failures)

	parent.queue_free()
	await process_frame


func _count_dropped_items(root_node: Node) -> int:
	var count := 0
	for child in root_node.get_children():
		if child.name.begins_with("DroppedItem"):
			count += 1
	return count


func _test_damage_number(failures: Array[String]) -> void:
	var damage_number_script := load(DAMAGE_NUMBER_PATH)
	if damage_number_script == null:
		failures.append("DamageNumber script should load from %s" % DAMAGE_NUMBER_PATH)
		return

	var damage_number := Label.new()
	damage_number.set_script(damage_number_script)
	damage_number.lifetime = 0.01
	root.add_child(damage_number)
	damage_number.setup(11)
	_assert_equal(damage_number.text, "11", "damage number should display integer damage", failures)
	await create_timer(0.05).timeout
	await process_frame
	_assert_equal(is_instance_valid(damage_number), false, "damage number should auto-remove after lifetime", failures)


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
