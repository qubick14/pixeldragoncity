extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const GameDataScript := preload("res://scripts/data/game_data.gd")
const InventoryModelScript := preload("res://scripts/inventory/inventory_model.gd")
const EquipmentModelScript := preload("res://scripts/inventory/equipment_model.gd")
const SaveManagerScript := preload("res://scripts/game/save_manager.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	await _test_initial_map_and_forest_transition(failures)
	await _test_village_chief_starts_and_completes_first_hunt(failures)
	await _test_forest_enemy_deaths_update_first_hunt(failures)
	await _test_village_merchant_opens_dialogue_and_shop(failures)
	await _test_v05_save_and_load_payload(failures)
	_test_player_interact_input_emits_request(failures)

	if failures.is_empty():
		print("v05_new_player_loop_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_initial_map_and_forest_transition(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	_assert_equal(main.has_node("MapManager"), true, "main scene should include a MapManager", failures)
	_assert_equal(main.has_node("MapRoot"), true, "main scene should include a MapRoot", failures)
	_assert_equal(main.has_node("Player"), true, "main scene should include the Player", failures)

	if not main.has_node("MapManager") or not main.has_node("MapRoot") or not main.has_node("Player"):
		main.queue_free()
		return

	var map_manager := main.get_node("MapManager")
	var player := main.get_node("Player") as Node2D

	_assert_equal(map_manager.current_map_id, "greenwood_village", "new game should start in Greenwood Village", failures)
	_assert_equal(map_manager.current_spawn_id, "village_spawn", "new game should use the village spawn", failures)

	var village: Node = map_manager.get_current_map()
	if village == null:
		failures.append("MapManager should expose the current village map")
		main.queue_free()
		return

	_assert_equal(village.name, "GreenwoodVillage", "initial map node should be GreenwoodVillage", failures)
	_assert_equal(village.has_node("SpawnPoints/VillageSpawn"), true, "village should have VillageSpawn", failures)
	_assert_equal(village.has_node("TransitionPoints/ToBlackWolfForest"), true, "village should have transition to Black Wolf Forest", failures)
	_assert_equal(village.has_node("NpcPoints/VillageChief"), true, "village should reserve a VillageChief point", failures)

	if village.has_node("SpawnPoints/VillageSpawn"):
		var village_spawn := village.get_node("SpawnPoints/VillageSpawn") as Node2D
		_assert_vector_close(player.global_position, village_spawn.global_position, 0.01, "player should be placed at VillageSpawn", failures)

	var loaded: bool = map_manager.load_map("black_wolf_forest", "forest_entry")
	_assert_equal(loaded, true, "MapManager should load Black Wolf Forest", failures)
	_assert_equal(map_manager.current_map_id, "black_wolf_forest", "current map id should update after transition", failures)
	_assert_equal(map_manager.current_spawn_id, "forest_entry", "current spawn id should update after transition", failures)

	var forest: Node = map_manager.get_current_map()
	if forest == null:
		failures.append("MapManager should expose the current forest map")
		main.queue_free()
		return

	_assert_equal(forest.name, "BlackWolfForest", "forest map node should be BlackWolfForest", failures)
	_assert_equal(forest.has_node("SpawnPoints/ForestEntry"), true, "forest should have ForestEntry spawn", failures)
	_assert_equal(forest.has_node("TransitionPoints/ToGreenwoodVillage"), true, "forest should have return transition to Greenwood Village", failures)
	_assert_equal(forest.has_node("MonsterSpawns/WildWolfSpawns"), true, "forest should reserve wild wolf spawn points", failures)
	_assert_equal(forest.has_node("MonsterSpawns/BlackWolfLeaderSpawn"), true, "forest should reserve Black Wolf Leader spawn", failures)

	if forest.has_node("SpawnPoints/ForestEntry"):
		var forest_spawn := forest.get_node("SpawnPoints/ForestEntry") as Node2D
		_assert_vector_close(player.global_position, forest_spawn.global_position, 0.01, "player should be placed at ForestEntry", failures)

	main.queue_free()


func _test_player_interact_input_emits_request(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)

	var player := main.get_node("Player")
	_assert_equal(player.has_signal("interact_requested"), true, "player should expose interact_requested signal", failures)
	if not player.has_signal("interact_requested"):
		main.queue_free()
		return

	var signal_count := [0]
	player.interact_requested.connect(func() -> void:
		signal_count[0] += 1
	)

	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	player._unhandled_input(event)
	_assert_equal(signal_count[0], 1, "interact input should emit interact_requested once", failures)

	main.queue_free()


func _test_village_chief_starts_and_completes_first_hunt(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	_assert_equal(main.has_node("QuestManager"), true, "main scene should include a QuestManager", failures)
	_assert_equal(InputMap.has_action("interact"), true, "project should define interact input", failures)

	if not main.has_node("QuestManager") or not main.has_node("MapManager"):
		main.queue_free()
		return

	var quest_manager := main.get_node("QuestManager")
	var map_manager := main.get_node("MapManager")
	var village: Node = map_manager.get_current_map()
	if village == null:
		failures.append("Village map should be loaded before testing the village chief")
		main.queue_free()
		return

	_assert_equal(quest_manager.get_quest_state("first_hunt"), "not_started", "first_hunt should start as not_started", failures)
	_assert_equal(village.has_node("Npcs/VillageChiefNpc"), true, "village should include VillageChiefNpc", failures)

	if not village.has_node("Npcs/VillageChiefNpc"):
		main.queue_free()
		return

	var village_chief := village.get_node("Npcs/VillageChiefNpc")
	_assert_equal(village_chief.npc_id, "village_chief", "VillageChiefNpc should use stable npc id", failures)

	village_chief.interact()
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "active", "interacting with village chief should start first_hunt", failures)
	_assert_equal(quest_manager.get_wild_wolf_defeated(), 0, "first_hunt wolf defeat count should start at 0", failures)

	for _i in range(3):
		quest_manager.record_wild_wolf_defeated()
	_assert_equal(quest_manager.get_wild_wolf_defeated(), 3, "first_hunt should count defeated wild wolves", failures)

	quest_manager.record_black_wolf_leader_defeated()
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "ready_to_turn_in", "Black Wolf Leader defeat should make first_hunt ready to turn in", failures)

	village_chief.interact()
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "completed", "second village chief interaction should complete first_hunt", failures)

	main.queue_free()


func _test_forest_enemy_deaths_update_first_hunt(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	if not main.has_node("QuestManager") or not main.has_node("MapManager"):
		failures.append("main scene should include QuestManager and MapManager before testing forest enemies")
		main.queue_free()
		return

	var quest_manager := main.get_node("QuestManager")
	var map_manager := main.get_node("MapManager")
	quest_manager.start_first_hunt()

	var loaded: bool = map_manager.load_map("black_wolf_forest", "forest_entry")
	_assert_equal(loaded, true, "forest enemy test should load Black Wolf Forest", failures)
	await process_frame

	var forest: Node = map_manager.get_current_map()
	if forest == null:
		failures.append("forest enemy test should have a current forest map")
		main.queue_free()
		return

	_assert_equal(forest.has_node("Enemies"), true, "Black Wolf Forest should include actual enemy instances", failures)
	if not forest.has_node("Enemies"):
		main.queue_free()
		return

	var enemies := forest.get_node("Enemies")
	_assert_equal(enemies.has_node("WildWolfA"), true, "forest should include WildWolfA", failures)
	_assert_equal(enemies.has_node("WildWolfB"), true, "forest should include WildWolfB", failures)
	_assert_equal(enemies.has_node("WildWolfC"), true, "forest should include WildWolfC", failures)
	_assert_equal(enemies.has_node("BlackWolfLeader"), true, "forest should include BlackWolfLeader", failures)
	if not enemies.has_node("WildWolfA") or not enemies.has_node("WildWolfB") or not enemies.has_node("WildWolfC") or not enemies.has_node("BlackWolfLeader"):
		main.queue_free()
		return

	for wolf_name in ["WildWolfA", "WildWolfB", "WildWolfC"]:
		var wolf := enemies.get_node(wolf_name)
		wolf.get_node("HealthComponent").apply_damage(999, main.get_node("Player"))

	_assert_equal(quest_manager.get_wild_wolf_defeated(), 3, "real wild wolf deaths should update first_hunt count", failures)
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "active", "three wild wolves alone should keep first_hunt active", failures)

	var leader := enemies.get_node("BlackWolfLeader")
	_assert_equal(leader.monster_id, "black_wolf_leader", "BlackWolfLeader should use boss monster id", failures)
	leader.get_node("HealthComponent").apply_damage(999, main.get_node("Player"))
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "ready_to_turn_in", "real Black Wolf Leader death should make first_hunt ready to turn in", failures)

	main.queue_free()


func _test_village_merchant_opens_dialogue_and_shop(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	if not main.has_node("MapManager") or not main.has_node("Player") or not main.has_node("UIRoot"):
		failures.append("main scene should include MapManager, Player, and UIRoot for NPC UI integration")
		main.queue_free()
		return

	var map_manager := main.get_node("MapManager")
	var village: Node = map_manager.get_current_map()
	if village == null:
		failures.append("Village map should be loaded before testing merchant interaction")
		main.queue_free()
		return

	_assert_equal(village.has_node("Npcs/MerchantNpc"), true, "village should include MerchantNpc", failures)
	_assert_equal(village.has_node("Npcs/BlacksmithNpc"), true, "village should include BlacksmithNpc", failures)
	if not village.has_node("Npcs/MerchantNpc"):
		main.queue_free()
		return

	var merchant := village.get_node("Npcs/MerchantNpc") as Node2D
	var player := main.get_node("Player") as Node2D
	player.global_position = merchant.global_position
	main._on_player_interact_requested()

	var ui_root := main.get_node("UIRoot")
	_assert_equal(ui_root.get_node("DialoguePanel").visible, true, "merchant interaction should open dialogue UI", failures)
	_assert_equal(ui_root.get_node("DialoguePanel/NameLabel").text, "行商阿岚", "merchant dialogue should show merchant name", failures)

	ui_root.get_node("DialoguePanel/ShopButton").pressed.emit()
	_assert_equal(ui_root.get_node("ShopPanel").visible, true, "merchant shop button should open shop UI", failures)
	_assert_equal(ui_root.get_node("ShopPanel/ShopNameLabel").text, "青木杂货铺", "merchant shop should show general store name", failures)

	main.queue_free()


func _test_v05_save_and_load_payload(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	var game_data := GameDataScript.new()
	_assert_equal(game_data.load_all(), true, "save test should load game data", failures)

	var inventory := InventoryModelScript.new()
	inventory.setup(game_data)
	inventory.add_gold(37)
	_assert_equal(inventory.add_item("wolf_pelt", 3), true, "save test should add wolf pelts", failures)
	_assert_equal(inventory.add_item("iron_sword", 1), true, "save test should add iron sword", failures)
	_assert_equal(inventory.add_item("leather_armor", 1), true, "save test should add leather armor", failures)

	var equipment := EquipmentModelScript.new()
	equipment.setup(game_data, inventory)
	_assert_equal(equipment.equip("iron_sword"), true, "save test should equip iron sword", failures)
	_assert_equal(equipment.equip("leather_armor"), true, "save test should equip leather armor", failures)

	var map_manager := main.get_node("MapManager")
	var quest_manager := main.get_node("QuestManager")
	map_manager.load_map("black_wolf_forest", "forest_entry")
	main.get_node("Player").global_position = Vector2(320, -48)
	quest_manager.start_first_hunt()
	for _i in range(3):
		quest_manager.record_wild_wolf_defeated()
	quest_manager.record_black_wolf_leader_defeated()

	var save_manager := SaveManagerScript.new()
	var payload: Dictionary = save_manager.build_payload(main, inventory, equipment)
	_assert_equal(payload.get("version"), 1, "save payload should include version 1", failures)
	_assert_equal(payload.get("player", {}).get("map_id"), "black_wolf_forest", "save payload should include current map id", failures)
	_assert_equal(payload.get("player", {}).get("spawn_id"), "forest_entry", "save payload should include current spawn id", failures)
	_assert_equal(payload.get("player", {}).get("position", {}).get("x"), 320.0, "save payload should include player x position", failures)
	_assert_equal(payload.get("inventory", [])[0].get("item_id"), "wolf_pelt", "save payload should include inventory entries", failures)
	_assert_equal(payload.get("inventory", [])[0].get("quantity"), 3, "save payload should include inventory quantities", failures)
	_assert_equal(payload.get("equipment", {}).get("weapon"), "iron_sword", "save payload should include equipped weapon", failures)
	_assert_equal(payload.get("equipment", {}).get("armor"), "leather_armor", "save payload should include equipped armor", failures)
	_assert_equal(payload.get("quests", {}).get("first_hunt", {}).get("state"), "ready_to_turn_in", "save payload should include first_hunt state", failures)
	_assert_equal(payload.get("quests", {}).get("first_hunt", {}).get("wild_wolf_defeated"), 3, "save payload should include wolf defeat count", failures)
	_assert_equal(payload.get("quests", {}).get("first_hunt", {}).get("black_wolf_leader_defeated"), true, "save payload should include leader defeat flag", failures)

	var save_path := "res://../godot/.tmp_v05_save_test.json"
	var save_result: Dictionary = save_manager.save_to_path(save_path, payload)
	_assert_equal(save_result.get("ok"), true, "save_to_path should report success", failures)
	var load_result: Dictionary = save_manager.load_from_path(save_path)
	_assert_equal(load_result.get("ok"), true, "load_from_path should report success for saved file", failures)
	_assert_equal(load_result.get("payload", {}).get("equipment", {}).get("weapon"), "iron_sword", "loaded payload should preserve equipped weapon", failures)

	var missing_result: Dictionary = save_manager.load_from_path("res://../godot/.missing_v05_save_test.json")
	_assert_equal(missing_result.get("ok"), true, "missing save should return a new game payload", failures)
	_assert_equal(missing_result.get("status"), "new_game", "missing save status should be new_game", failures)
	_assert_equal(missing_result.get("payload", {}).get("player", {}).get("map_id"), "greenwood_village", "new game payload should start in Greenwood Village", failures)

	var bad_version := payload.duplicate(true)
	bad_version["version"] = 999
	save_manager.save_to_path(save_path, bad_version)
	var bad_version_result: Dictionary = save_manager.load_from_path(save_path)
	_assert_equal(bad_version_result.get("ok"), false, "wrong save version should be recoverable failure", failures)
	_assert_equal(bad_version_result.get("status"), "unsupported_version", "wrong save version should report unsupported_version", failures)

	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	save_manager.free()
	equipment.free()
	inventory.free()
	game_data.free()
	main.queue_free()


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])


func _assert_vector_close(actual: Vector2, expected: Vector2, tolerance: float, message: String, failures: Array[String]) -> void:
	if actual.distance_to(expected) > tolerance:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
