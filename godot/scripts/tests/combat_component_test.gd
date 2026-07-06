extends SceneTree

const HEALTH_COMPONENT_PATH := "res://scripts/combat/health_component.gd"
const HITBOX_PATH := "res://scripts/combat/hitbox.gd"
const HURTBOX_PATH := "res://scripts/combat/hurtbox.gd"


func _initialize() -> void:
	var failures: Array[String] = []
	_test_health_component(failures)
	_test_hitbox_and_hurtbox(failures)

	if failures.is_empty():
		print("combat_component_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_health_component(failures: Array[String]) -> void:
	var health_script := load(HEALTH_COMPONENT_PATH)
	if health_script == null:
		failures.append("HealthComponent script should load from %s" % HEALTH_COMPONENT_PATH)
		return

	var health := Node.new()
	health.set_script(health_script)
	root.add_child(health)
	health.setup(50, 3)

	_assert_equal(health.max_hp, 50, "setup should set max_hp", failures)
	_assert_equal(health.current_hp, 50, "setup should start current_hp at max_hp", failures)
	_assert_equal(health.defense, 3, "setup should set defense", failures)

	var death_count := [0]
	health.died.connect(func(_source: Variant) -> void:
		death_count[0] += 1
	)

	var damage: int = health.apply_damage(10, null)
	_assert_equal(damage, 7, "damage should subtract defense from raw attack", failures)
	_assert_equal(health.current_hp, 43, "damage should reduce current_hp", failures)

	damage = health.apply_damage(1, null)
	_assert_equal(damage, 1, "damage should always be at least 1", failures)
	_assert_equal(health.current_hp, 42, "minimum damage should reduce current_hp", failures)

	health.heal(999)
	_assert_equal(health.current_hp, 50, "heal should not exceed max_hp", failures)

	health.apply_damage(999, null)
	_assert_equal(health.current_hp, 0, "damage should clamp current_hp at 0", failures)
	_assert_equal(health.is_dead(), true, "is_dead should be true at 0 HP", failures)
	_assert_equal(death_count[0], 1, "died should emit once on lethal damage", failures)

	health.apply_damage(999, null)
	_assert_equal(death_count[0], 1, "died should not emit again after already dead", failures)

	health.queue_free()


func _test_hitbox_and_hurtbox(failures: Array[String]) -> void:
	var health_script := load(HEALTH_COMPONENT_PATH)
	var hitbox_script := load(HITBOX_PATH)
	var hurtbox_script := load(HURTBOX_PATH)
	if health_script == null or hitbox_script == null or hurtbox_script == null:
		failures.append("HealthComponent, Hitbox, and Hurtbox scripts should all load")
		return

	var attacker := Node2D.new()
	attacker.name = "Attacker"
	root.add_child(attacker)

	var target := Node2D.new()
	target.name = "Target"
	root.add_child(target)

	var health := Node.new()
	health.name = "HealthComponent"
	health.set_script(health_script)
	target.add_child(health)
	health.setup(30, 2)

	var hurtbox := Area2D.new()
	hurtbox.name = "Hurtbox"
	hurtbox.set_script(hurtbox_script)
	target.add_child(hurtbox)

	var hitbox := Area2D.new()
	hitbox.name = "Hitbox"
	hitbox.set_script(hitbox_script)
	attacker.add_child(hitbox)
	hitbox.setup(attacker, 8)

	var damage: int = hurtbox.receive_hit(hitbox)
	_assert_equal(damage, 6, "hurtbox should forward hitbox attack to health component", failures)
	_assert_equal(health.current_hp, 24, "valid hit should reduce target HP", failures)

	hitbox.enabled = false
	damage = hurtbox.receive_hit(hitbox)
	_assert_equal(damage, 0, "disabled hitbox should not damage", failures)
	_assert_equal(health.current_hp, 24, "disabled hitbox should leave HP unchanged", failures)

	hitbox.enabled = true
	hitbox.owner_node = target
	damage = hurtbox.receive_hit(hitbox)
	_assert_equal(damage, 0, "hurtbox should ignore hitboxes owned by the same actor", failures)
	_assert_equal(health.current_hp, 24, "self hit should leave HP unchanged", failures)

	attacker.queue_free()
	target.queue_free()


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
