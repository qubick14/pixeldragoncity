extends SceneTree

const ASSET_PATHS := [
	"res://assets/sprites/player_swordsman_sheet.png",
	"res://assets/sprites/swordsman/swordsman_walk_8dir_test_atlas.png",
	"res://assets/sprites/swordsman/swordsman_walk_9dir_v2_atlas.png",
	"res://assets/sprites/swordsman/swordsman_walk_blockout_v1_atlas.png",
	"res://assets/sprites/monster_sheet.png",
	"res://assets/items/item_icons_sheet.png",
	"res://assets/tilesets/environment_tileset_v1.png",
	"res://assets/ui/ui_atlas.png",
	"res://assets/portraits/swordsman_portrait_v1.png",
	"res://assets/portraits/character_portrait_direction_v1.png",
	"res://assets/portraits/monster_portrait_direction_v1.png",
	"res://assets/backgrounds/test_map_background_v1.png",
]

const PlayerScene := preload("res://scenes/actors/player.tscn")
const MainScene := preload("res://scenes/main.tscn")
const GreenwoodVillageScene := preload("res://scenes/maps/greenwood_village.tscn")
const BlackWolfForestScene := preload("res://scenes/maps/black_wolf_forest.tscn")
const LootDropScene := preload("res://scenes/loot/dropped_item.tscn")


func _initialize() -> void:
	var failures: Array[String] = []

	for asset_path in ASSET_PATHS:
		var texture := ResourceLoader.load(asset_path)
		if texture == null:
			failures.append("Failed to load %s" % asset_path)
		elif not texture is Texture2D:
			failures.append("%s loaded as %s, not Texture2D" % [asset_path, texture.get_class()])

	await _test_assets_are_visible_in_scenes(failures)
	_test_v05_maps_have_placeholder_tilesets(failures)
	_test_dropped_item_scene(failures)

	if failures.is_empty():
		print("asset_load_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_assets_are_visible_in_scenes(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)
	if not player.has_node("VisualRoot/GeneratedSprite"):
		failures.append("Player scene should display the generated swordsman sprite")
	player.free()

	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame
	if not main.has_node("ArtPreview"):
		failures.append("Main scene should include ArtPreview for generated assets")
	if not main.has_node("MapRoot/GreenwoodVillage"):
		failures.append("Main scene should load GreenwoodVillage under MapRoot")
	if not main.has_node("HUD/GeneratedUiFrame"):
		failures.append("HUD should display generated UI art")
	if not main.has_node("HUD/CharacterPortrait"):
		failures.append("HUD should display generated character portrait art")
	if not main.has_node("MenuOverlay"):
		failures.append("Main scene should include inventory and equipment menu overlay")
	if not main.has_node("MenuOverlay/InventoryPanel"):
		failures.append("MenuOverlay should display an inventory panel")
	if not main.has_node("MenuOverlay/EquipmentPanel"):
		failures.append("MenuOverlay should display an equipment panel")
	main.free()


func _test_v05_maps_have_placeholder_tilesets(failures: Array[String]) -> void:
	var tile_set := ResourceLoader.load("res://resources/tilesets/environment_placeholder_tileset.tres")
	if tile_set == null:
		failures.append("v0.5 should provide an environment placeholder TileSet resource")
	elif not tile_set is TileSet:
		failures.append("environment placeholder resource should load as TileSet")

	var village := GreenwoodVillageScene.instantiate()
	if not village.has_node("PlaceholderTileLayer"):
		failures.append("Greenwood Village should include PlaceholderTileLayer")
	else:
		var village_layer := village.get_node("PlaceholderTileLayer")
		if village_layer.get("tile_set") == null:
			failures.append("Greenwood Village PlaceholderTileLayer should reference a TileSet")
	village.free()

	var forest := BlackWolfForestScene.instantiate()
	if not forest.has_node("PlaceholderTileLayer"):
		failures.append("Black Wolf Forest should include PlaceholderTileLayer")
	else:
		var forest_layer := forest.get_node("PlaceholderTileLayer")
		if forest_layer.get("tile_set") == null:
			failures.append("Black Wolf Forest PlaceholderTileLayer should reference a TileSet")
	forest.free()


func _test_dropped_item_scene(failures: Array[String]) -> void:
	var dropped_item := LootDropScene.instantiate()
	if dropped_item.name != "DroppedItem":
		failures.append("Dropped item scene root should be named DroppedItem")
	if not dropped_item.has_node("Icon"):
		failures.append("Dropped item scene should include an Icon sprite")
	if not dropped_item.has_node("PickupShape"):
		failures.append("Dropped item scene should include a PickupShape")
	dropped_item.free()
