extends Node

const SAVE_VERSION := 1
const DEFAULT_MAP_ID := "greenwood_village"
const DEFAULT_SPAWN_ID := "village_spawn"


func build_payload(main: Node, inventory_model: Node = null, equipment_model: Node = null) -> Dictionary:
	var map_manager := main.get_node_or_null("MapManager")
	var player := main.get_node_or_null("Player") as Node2D
	var health_component := main.get_node_or_null("Player/HealthComponent")
	var quest_manager := main.get_node_or_null("QuestManager")

	var map_id := DEFAULT_MAP_ID
	var spawn_id := DEFAULT_SPAWN_ID
	if map_manager != null:
		map_id = String(map_manager.get("current_map_id"))
		spawn_id = String(map_manager.get("current_spawn_id"))

	var position := Vector2.ZERO
	if player != null:
		position = player.global_position

	var current_hp := 100
	if health_component != null:
		current_hp = int(health_component.get("current_hp"))

	var player_payload := {
		"map_id": map_id,
		"spawn_id": spawn_id,
		"position": {"x": position.x, "y": position.y},
		"level": 1,
		"exp": 0,
		"current_hp": current_hp,
		"current_mp": 30,
		"gold": _get_inventory_gold(inventory_model),
	}

	return {
		"version": SAVE_VERSION,
		"player": player_payload,
		"inventory": _get_inventory_entries(inventory_model),
		"equipment": _get_equipment_slots(equipment_model),
		"quests": {
			"first_hunt": _get_first_hunt_payload(quest_manager),
		},
	}


func create_new_game_payload() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"player": {
			"map_id": DEFAULT_MAP_ID,
			"spawn_id": DEFAULT_SPAWN_ID,
			"position": {"x": 0.0, "y": 0.0},
			"level": 1,
			"exp": 0,
			"current_hp": 100,
			"current_mp": 30,
			"gold": 0,
		},
		"inventory": [],
		"equipment": {
			"weapon": "",
			"armor": "",
		},
		"quests": {
			"first_hunt": {
				"state": "not_started",
				"wild_wolf_defeated": 0,
				"black_wolf_leader_defeated": false,
			},
		},
	}


func save_to_path(path: String, payload: Dictionary) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"ok": false, "status": "write_failed", "error": FileAccess.get_open_error()}

	file.store_string(JSON.stringify(payload, "\t"))
	return {"ok": true, "status": "saved", "path": path}


func load_from_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": true, "status": "new_game", "payload": create_new_game_payload()}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"ok": false, "status": "read_failed", "error": FileAccess.get_open_error()}

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"ok": false, "status": "parse_failed"}

	var payload: Dictionary = parsed
	if int(payload.get("version", 0)) != SAVE_VERSION:
		return {"ok": false, "status": "unsupported_version", "payload": payload}

	return {"ok": true, "status": "loaded", "payload": payload}


func _get_inventory_gold(inventory_model: Node) -> int:
	if inventory_model == null:
		return 0
	return int(inventory_model.get("gold"))


func _get_inventory_entries(inventory_model: Node) -> Array:
	if inventory_model == null or not inventory_model.has_method("get_entries"):
		return []
	return inventory_model.get_entries()


func _get_equipment_slots(equipment_model: Node) -> Dictionary:
	if equipment_model == null or not equipment_model.has_method("get_equipped_items"):
		return {"weapon": "", "armor": ""}
	var slots: Dictionary = equipment_model.get_equipped_items()
	return {
		"weapon": String(slots.get("weapon", "")),
		"armor": String(slots.get("armor", "")),
	}


func _get_first_hunt_payload(quest_manager: Node) -> Dictionary:
	var state := "not_started"
	var wild_wolf_defeated := 0
	if quest_manager != null:
		if quest_manager.has_method("get_quest_state"):
			state = quest_manager.get_quest_state("first_hunt")
		if quest_manager.has_method("get_wild_wolf_defeated"):
			wild_wolf_defeated = quest_manager.get_wild_wolf_defeated()

	return {
		"state": state,
		"wild_wolf_defeated": wild_wolf_defeated,
		"black_wolf_leader_defeated": state == "ready_to_turn_in" or state == "completed",
	}
