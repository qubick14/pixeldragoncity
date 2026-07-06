extends CanvasLayer

const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")
const UiDemoState := preload("res://scripts/ui/ui_demo_state.gd")

var _demo_state := UiDemoState.new()
var _npcs: Array = []
var _shops: Array = []
var _active_panel: Control = null
var _loaded: bool = false


func _ready() -> void:
	load_demo_state()
	close_all_panels()
	if not $DialoguePanel.shop_requested.is_connected(show_shop):
		$DialoguePanel.shop_requested.connect(show_shop)


func load_demo_state() -> void:
	var loader := JsonDataLoader.new()
	_demo_state.load_state()
	var npc_data: Variant = loader.load_json("res://../data/npcs.json")
	var shop_data: Variant = loader.load_json("res://../data/shops.json")
	_npcs = npc_data if npc_data is Array else []
	_shops = shop_data if shop_data is Array else []

	var player := _demo_state.get_player()
	if not player.is_empty():
		var hp: Dictionary = player.get("hp", {}) as Dictionary
		var mp: Dictionary = player.get("mp", {}) as Dictionary
		var exp: Dictionary = player.get("exp", {}) as Dictionary
		$HUD.set_health(int(hp.get("current", 0)), int(hp.get("max", 1)))
		$HUD.set_mana(int(mp.get("current", 0)), int(mp.get("max", 1)))
		$HUD.set_experience(int(exp.get("current", 0)), int(exp.get("max", 1)))
		$HUD.set_gold(_demo_state.get_gold())
		$HUD.set_level(int(player.get("level", 1)))

	$InventoryPanel.set_inventory(_demo_state.get_inventory())
	$EquipmentPanel.set_equipment(_demo_state.get_equipment(), _demo_state.get_stats())
	_loaded = true


func show_inventory() -> void:
	_ensure_loaded()
	close_all_panels()
	$InventoryPanel.visible = true
	_active_panel = $InventoryPanel


func show_equipment() -> void:
	_ensure_loaded()
	close_all_panels()
	$EquipmentPanel.visible = true
	_active_panel = $EquipmentPanel


func show_dialogue(npc_id: String) -> void:
	_ensure_loaded()
	if not $DialoguePanel.shop_requested.is_connected(show_shop):
		$DialoguePanel.shop_requested.connect(show_shop)
	var npc := _find_by_id(_npcs, npc_id)
	if npc.is_empty():
		return
	close_all_panels()
	$DialoguePanel.start_dialogue(npc)
	_active_panel = $DialoguePanel


func show_shop(shop_id: String) -> void:
	_ensure_loaded()
	var shop := _find_by_id(_shops, shop_id)
	if shop.is_empty():
		return
	close_all_panels()
	$ShopPanel.set_shop(shop, _demo_state.get_gold())
	_active_panel = $ShopPanel


func close_active_panel() -> void:
	if _active_panel != null:
		_active_panel.visible = false
	_active_panel = null


func close_all_panels() -> void:
	$InventoryPanel.visible = false
	$EquipmentPanel.visible = false
	$DialoguePanel.visible = false
	$ShopPanel.visible = false
	_active_panel = null


func _find_by_id(items: Array, id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and item.get("id", "") == id:
			return item
	return {}


func _ensure_loaded() -> void:
	if not _loaded:
		load_demo_state()
