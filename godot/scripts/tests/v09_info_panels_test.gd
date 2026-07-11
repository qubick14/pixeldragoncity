extends SceneTree
# Verifies the skills / quests / map info panels and their routing in ui_root.gd,
# plus QuestManager.get_all_quest_states. Headless (no rendering needed).
const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const QuestManager := preload("res://scripts/game/quest_manager.gd")


func _initialize() -> void:
	var failures: Array[String] = []

	var qm := QuestManager.new()
	if not qm.get_all_quest_states().has("first_hunt"):
		failures.append("QuestManager.get_all_quest_states should include first_hunt")

	var ui := UIRootScene.instantiate()
	root.add_child(ui)
	await process_frame

	ui.set_skills([
		{"name": "普通斩击", "icon_index": 0, "cooldown": 0.45, "mp_cost": 0, "multiplier": 1.0},
		{"name": "重斩", "icon_index": 1, "cooldown": 1.2, "mp_cost": 5, "multiplier": 1.8},
	])
	_expect(_count(ui, "SkillTalentPanel/Content/SkillList") == 2, "skill list should render 2 rows", failures)

	ui.set_quests([
		{"title": "初次狩猎", "description": "清剿野狼", "objective": "击败黑狼头目", "state": "active"},
	])
	_expect(_count(ui, "QuestPanel/Content/QuestList") == 1, "quest list should render 1 entry", failures)

	ui.set_map([
		{"id": "greenwood_village", "name": "青木村", "connections": ["black_wolf_forest"]},
		{"id": "black_wolf_forest", "name": "黑狼林", "connections": ["greenwood_village"]},
	], "black_wolf_forest")
	_expect(_count(ui, "MapPanel/Labels") == 2, "map should render 2 node labels", failures)

	# Mutual exclusion among the three center panels.
	ui.toggle_skills()
	_expect(ui.get_node("SkillTalentPanel").visible, "toggle_skills shows skills", failures)
	ui.toggle_quests()
	_expect(ui.get_node("QuestPanel").visible, "toggle_quests shows quests", failures)
	_expect(not ui.get_node("SkillTalentPanel").visible, "opening quests should hide skills", failures)
	ui.toggle_map()
	_expect(ui.get_node("MapPanel").visible, "toggle_map shows map", failures)
	_expect(not ui.get_node("QuestPanel").visible, "opening map should hide quests", failures)

	# Esc / close_all closes everything.
	ui.close_all_panels()
	_expect(not ui.get_node("MapPanel").visible, "close_all_panels hides map", failures)
	_expect(not ui.get_node("SkillTalentPanel").visible, "close_all_panels hides skills", failures)

	ui.queue_free()
	await process_frame

	if failures.is_empty():
		print("v09_info_panels_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v09_info_panels_test: FAIL")
	quit(1)


func _count(ui: Node, path: String) -> int:
	var node := ui.get_node_or_null(path)
	return node.get_child_count() if node != null else -1


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
