extends CanvasLayer

const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")
const UiDemoState := preload("res://scripts/ui/ui_demo_state.gd")
const SkillTalentPanel := preload("res://scripts/ui/skill_talent_panel.gd")
const QuestPanel := preload("res://scripts/ui/quest_panel.gd")
const MapPanel := preload("res://scripts/ui/map_panel.gd")

var _demo_state := UiDemoState.new()
var _npcs: Array = []
var _shops: Array = []
var _active_panel: Control = null
var _loaded: bool = false

var _skill_panel: Control = null
var _quest_panel: Control = null
var _map_panel: Control = null


func _ready() -> void:
	_ensure_info_panels()
	load_demo_state()
	close_all_panels()
	if not $DialoguePanel.shop_requested.is_connected(show_shop):
		$DialoguePanel.shop_requested.connect(show_shop)


func _ensure_info_panels() -> void:
	if _skill_panel == null:
		_skill_panel = _add_center_panel(SkillTalentPanel.new(), "SkillTalentPanel")
	if _quest_panel == null:
		_quest_panel = _add_center_panel(QuestPanel.new(), "QuestPanel")
	if _map_panel == null:
		_map_panel = _add_center_panel(MapPanel.new(), "MapPanel")


func _add_center_panel(panel: Control, panel_name: String) -> Control:
	panel.name = panel_name
	add_child(panel)
	# _ready has now run, so custom_minimum_size is set — center it on screen.
	var size := panel.custom_minimum_size
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -size.x * 0.5
	panel.offset_right = size.x * 0.5
	panel.offset_top = -size.y * 0.5
	panel.offset_bottom = size.y * 0.5
	panel.visible = false
	return panel


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
		var hud := get_node_or_null("../HUD")
		if hud != null:
			hud.set_health(int(hp.get("current", 0)), int(hp.get("max", 1)))
			hud.set_mana(int(mp.get("current", 0)), int(mp.get("max", 1)))
			hud.set_experience(int(exp.get("current", 0)), int(exp.get("max", 1)))
			hud.set_gold(_demo_state.get_gold())
			hud.set_level(int(player.get("level", 1)))

	$InventoryPanel.set_inventory(_demo_state.get_inventory())
	$EquipmentPanel.set_equipment(_demo_state.get_equipment(), _demo_state.get_stats())
	_loaded = true


func set_live_inventory(display: Array) -> void:
	_ensure_loaded()
	$InventoryPanel.set_inventory(display)


func set_live_equipment(equipment: Dictionary, stats: Dictionary) -> void:
	_ensure_loaded()
	$EquipmentPanel.set_equipment(equipment, stats)


func get_inventory_panel() -> Control:
	return $InventoryPanel


func show_inventory() -> void:
	# Inventory and equipment are independent panels that may stay open together.
	_ensure_loaded()
	_close_menu_overlay()
	$InventoryPanel.visible = true


func show_equipment() -> void:
	_ensure_loaded()
	_close_menu_overlay()
	$EquipmentPanel.visible = true


func toggle_inventory() -> void:
	if $InventoryPanel.visible:
		$InventoryPanel.visible = false
	else:
		show_inventory()


func toggle_equipment() -> void:
	if $EquipmentPanel.visible:
		$EquipmentPanel.visible = false
	else:
		show_equipment()


# --- Center info panels: skills / quests / map (mutually exclusive) -----------
func set_skills(skills: Array) -> void:
	_ensure_info_panels()
	_skill_panel.set_skills(skills)


func set_quests(quests: Array) -> void:
	_ensure_info_panels()
	_quest_panel.set_quests(quests)


func set_map(maps: Array, current_id: String) -> void:
	_ensure_info_panels()
	_map_panel.set_map(maps, current_id)


func toggle_skills() -> void:
	_toggle_info_panel(_skill_panel)


func toggle_quests() -> void:
	_toggle_info_panel(_quest_panel)


func toggle_map() -> void:
	_toggle_info_panel(_map_panel)


func _toggle_info_panel(panel: Control) -> void:
	_ensure_info_panels()
	var want := not panel.visible
	# The three center panels are mutually exclusive.
	_skill_panel.visible = false
	_quest_panel.visible = false
	_map_panel.visible = false
	panel.visible = want
	_close_menu_overlay()


func show_dialogue(npc_id: String) -> void:
	_ensure_loaded()
	if not $DialoguePanel.shop_requested.is_connected(show_shop):
		$DialoguePanel.shop_requested.connect(show_shop)
	var npc := _find_by_id(_npcs, npc_id)
	if npc.is_empty():
		return
	close_all_panels()
	_close_menu_overlay()
	$DialoguePanel.start_dialogue(npc)
	_active_panel = $DialoguePanel


func show_shop(shop_id: String) -> void:
	_ensure_loaded()
	var shop := _find_by_id(_shops, shop_id)
	if shop.is_empty():
		return
	close_all_panels()
	_close_menu_overlay()
	$ShopPanel.set_shop(shop, _demo_state.get_gold())
	_active_panel = $ShopPanel


func close_active_panel() -> void:
	# Esc closes every open panel, including simultaneously-open inventory + equipment.
	close_all_panels()


func close_all_panels() -> void:
	$InventoryPanel.visible = false
	$EquipmentPanel.visible = false
	$DialoguePanel.visible = false
	$ShopPanel.visible = false
	if _skill_panel != null:
		_skill_panel.visible = false
	if _quest_panel != null:
		_quest_panel.visible = false
	if _map_panel != null:
		_map_panel.visible = false
	_active_panel = null


func _close_menu_overlay() -> void:
	var menu_overlay := get_node_or_null("../MenuOverlay")
	if menu_overlay == null:
		return
	if menu_overlay.has_method("hide_menu"):
		menu_overlay.hide_menu()
	else:
		menu_overlay.visible = false


func _find_by_id(items: Array, id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and item.get("id", "") == id:
			return item
	return {}


func _ensure_loaded() -> void:
	if not _loaded:
		load_demo_state()
