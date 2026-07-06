extends RefCounted

const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")

var data: Dictionary = {}


func load_state(path: String = "res://../data/ui_demo_state.json") -> bool:
	var loader := JsonDataLoader.new()
	var loaded: Variant = loader.load_json(path)
	if not loaded is Dictionary:
		data = {}
		return false
	data = loaded
	return true


func get_player() -> Dictionary:
	return data.get("player", {}) as Dictionary


func get_inventory() -> Array:
	return data.get("inventory", []) as Array


func get_equipment() -> Dictionary:
	return data.get("equipment", {}) as Dictionary


func get_stats() -> Dictionary:
	var player := get_player()
	return player.get("stats", {}) as Dictionary


func get_gold() -> int:
	return int(get_player().get("gold", 0))
