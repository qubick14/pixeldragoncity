extends Node

const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")

var items: Dictionary = {}
var monsters: Dictionary = {}
var skills: Dictionary = {}


func load_all() -> bool:
	return load_items() and load_monsters() and load_skills()


func load_items(path: String = "res://../data/items.json") -> bool:
	var loader := JsonDataLoader.new()
	var item_rows: Variant = loader.load_json(path)
	if not item_rows is Array:
		return false
	items = _index_by_id(item_rows)
	return true


func load_monsters(path: String = "res://../data/monsters.json") -> bool:
	var loader := JsonDataLoader.new()
	var monster_rows: Variant = loader.load_json(path)
	if not monster_rows is Array:
		return false
	monsters = _index_by_id(monster_rows)
	return true


func load_skills(path: String = "res://../data/skills.json") -> bool:
	var loader := JsonDataLoader.new()
	var skill_rows: Variant = loader.load_json(path)
	if not skill_rows is Array:
		return false
	skills = _index_by_id(skill_rows)
	return true


func get_skill(skill_id: String) -> Dictionary:
	return skills.get(skill_id, {})


func has_skill(skill_id: String) -> bool:
	return skills.has(skill_id)


func get_skills_for_class(class_id: String) -> Array:
	var result: Array = []
	for skill_id in skills:
		var skill: Dictionary = skills[skill_id]
		if String(skill.get("class", "")) == class_id:
			result.append(skill)
	result.sort_custom(func(a, b): return int(a.get("level", 1)) < int(b.get("level", 1)))
	return result


func get_item(item_id: String) -> Dictionary:
	return items.get(item_id, {})


func has_item(item_id: String) -> bool:
	return items.has(item_id)


func get_monster(monster_id: String) -> Dictionary:
	return monsters.get(monster_id, {})


func has_monster(monster_id: String) -> bool:
	return monsters.has(monster_id)


func get_item_slot(item_id: String) -> String:
	var item: Dictionary = get_item(item_id)
	if item.has("slot"):
		return String(item["slot"])

	match String(item.get("type", "")):
		"weapon":
			return "weapon"
		"armor":
			return "armor"
		_:
			return ""


func get_item_stack_rules(item_id: String) -> Dictionary:
	var item: Dictionary = get_item(item_id)
	if item.is_empty():
		return {"stackable": false, "max_stack": 0}
	if item.has("stackable") or item.has("max_stack"):
		return {
			"stackable": bool(item.get("stackable", false)),
			"max_stack": int(item.get("max_stack", 1)),
		}

	match String(item.get("type", "")):
		"material", "consumable":
			return {"stackable": true, "max_stack": 99}
		_:
			return {"stackable": false, "max_stack": 1}


func validate_monster_drops() -> Array[String]:
	var failures: Array[String] = []
	for monster_id in monsters:
		var monster: Dictionary = monsters[monster_id]
		for drop in monster.get("drops", []):
			if not drop is Dictionary:
				failures.append("%s has a non-dictionary drop row" % monster_id)
				continue
			var item_id: String = String(drop.get("item_id", ""))
			if not has_item(item_id):
				failures.append("%s references missing item %s" % [monster_id, item_id])
	return failures


func _index_by_id(rows: Array) -> Dictionary:
	var indexed: Dictionary = {}
	for row in rows:
		if row is Dictionary:
			var id: String = String(row.get("id", ""))
			if not id.is_empty():
				indexed[id] = row
	return indexed
