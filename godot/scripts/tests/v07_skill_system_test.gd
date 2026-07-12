extends SceneTree
# v0.6: verifies the swordsman skill system — skill bar wiring, MP cost gating,
# cooldown gating, and damage-multiplier scaling through the attack hitbox.
const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame

	var player := main.get_node("Player")
	var hitbox := player.get_node("AttackHitbox")
	var bar: Array = player.get_skill_bar()

	# Two swordsman melee skills + the prototype fireball granted in main.
	if bar.size() != 3:
		failures.append("swordsman skill bar should have 3 skills, got %d" % bar.size())
	else:
		if String(bar[0].get("id", "")) != "basic_slash":
			failures.append("slot 0 should be basic_slash, got %s" % str(bar[0].get("id")))
		if String(bar[1].get("id", "")) != "heavy_slash":
			failures.append("slot 1 should be heavy_slash, got %s" % str(bar[1].get("id")))
		if String(bar[2].get("id", "")) != "fireball":
			failures.append("slot 2 should be fireball, got %s" % str(bar[2].get("id")))

	var base_attack := int(player.get("attack"))
	var basic: Dictionary = bar[0]
	var heavy: Dictionary = bar[1]

	# MP gate: not enough MP for heavy_slash (cost 5) -> rejected, no cooldown set.
	player.set("current_mp", 1)
	if player.use_skill(heavy):
		failures.append("heavy_slash should fail with insufficient MP")
	if int(player.get("current_mp")) != 1:
		failures.append("MP should be unchanged after a rejected skill")
	if player.get_skill_cooldown_remaining("heavy_slash") > 0.0:
		failures.append("rejected skill should not start a cooldown")

	# Basic slash: costs 0 MP, damage = attack * 1.0.
	player.set("current_mp", 40)
	if not player.use_skill(basic):
		failures.append("basic_slash should succeed")
	if int(hitbox.get("attack")) != base_attack:
		failures.append("basic_slash damage expected %d, got %d" % [base_attack, int(hitbox.get("attack"))])
	if int(player.get("current_mp")) != 40:
		failures.append("basic_slash should cost no MP")
	if player.get_skill_cooldown_remaining("basic_slash") <= 0.0:
		failures.append("basic_slash should be on cooldown after use")

	# Still mid-swing / on cooldown -> immediate re-use rejected.
	if player.use_skill(basic):
		failures.append("basic_slash should be rejected while on cooldown")

	# Let the swing + basic cooldown clear, then cast heavy_slash.
	await create_timer(0.7).timeout
	var expected_heavy := int(round(float(base_attack) * 1.8))
	if not player.use_skill(heavy):
		failures.append("heavy_slash should succeed with full MP off cooldown")
	if int(hitbox.get("attack")) != expected_heavy:
		failures.append("heavy_slash damage expected %d, got %d" % [expected_heavy, int(hitbox.get("attack"))])
	if int(player.get("current_mp")) != 35:
		failures.append("heavy_slash should cost 5 MP (40->35), got %d" % int(player.get("current_mp")))
	if player.get_skill_cooldown_remaining("heavy_slash") <= 0.0:
		failures.append("heavy_slash should be on cooldown after use")

	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("v07_skill_system_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v07_skill_system_test: FAIL")
	quit(1)
