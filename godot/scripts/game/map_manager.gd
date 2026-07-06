extends Node

signal map_loaded(map_id: String, map_node: Node)

const MAP_SCENES := {
	"greenwood_village": preload("res://scenes/maps/greenwood_village.tscn"),
	"black_wolf_forest": preload("res://scenes/maps/black_wolf_forest.tscn"),
}

const SPAWN_NODE_PATHS := {
	"village_spawn": "SpawnPoints/VillageSpawn",
	"forest_entry": "SpawnPoints/ForestEntry",
}

@export var map_root_path: NodePath = NodePath("../MapRoot")
@export var player_path: NodePath = NodePath("../Player")

var current_map_id: String = ""
var current_spawn_id: String = ""

var _current_map: Node2D = null


func load_map(map_id: String, spawn_id: String) -> bool:
	if not MAP_SCENES.has(map_id):
		push_warning("Unknown map id: %s" % map_id)
		return false

	var map_root := get_node_or_null(map_root_path)
	if map_root == null:
		push_warning("Map root is missing")
		return false

	if _current_map != null:
		_current_map.queue_free()
		_current_map = null

	_current_map = MAP_SCENES[map_id].instantiate() as Node2D
	map_root.add_child(_current_map)
	current_map_id = map_id
	current_spawn_id = spawn_id
	_place_player_at_spawn(spawn_id)
	map_loaded.emit(current_map_id, _current_map)
	return true


func get_current_map() -> Node2D:
	return _current_map


func _place_player_at_spawn(spawn_id: String) -> void:
	var player := get_node_or_null(player_path) as Node2D
	if player == null or _current_map == null:
		return

	var spawn_path := String(SPAWN_NODE_PATHS.get(spawn_id, ""))
	if spawn_path.is_empty() or not _current_map.has_node(spawn_path):
		push_warning("Spawn id %s is missing on map %s" % [spawn_id, current_map_id])
		return

	var spawn := _current_map.get_node(spawn_path) as Node2D
	player.global_position = spawn.global_position
