extends Control

signal equip_slot_clicked(slot_id: String, item_id: String, double_click: bool)

const ItemSlotScene := preload("res://scenes/ui/item_slot.tscn")
const EQUIPMENT_SLOTS := ["weapon", "armor", "helmet", "necklace", "ring"]
const SLOT_NAMES := {
	"weapon": "武器",
	"armor": "护甲",
	"helmet": "头盔",
	"necklace": "项链",
	"ring": "戒指",
}

var _slot_nodes: Dictionary = {}


func _ready() -> void:
	_ensure_panel_background()
	_ensure_slots()


func set_equipment(equipment: Dictionary, stats: Dictionary) -> void:
	_ensure_panel_background()
	_ensure_slots()
	for slot_id in EQUIPMENT_SLOTS:
		var slot := get_equipment_slot(slot_id)
		var data: Dictionary = equipment.get(slot_id, {}) as Dictionary
		if data.has("item_id"):
			slot.set_item(data)
		else:
			slot.set_empty()
	_update_stats(stats)


func get_equipment_slot(slot_id: String) -> Control:
	_ensure_slots()
	return _slot_nodes.get(slot_id, null)


func set_portrait(texture: Texture2D) -> void:
	var portrait := get_node_or_null("PortraitFrame/PortraitPreview") as TextureRect
	if portrait != null:
		portrait.texture = texture


func _ensure_slots() -> void:
	_ensure_panel_background()
	var slot_list := get_node_or_null("SlotList") as VBoxContainer
	if slot_list == null:
		return
	for slot_id in EQUIPMENT_SLOTS:
		if _slot_nodes.has(slot_id):
			continue
		var row := HBoxContainer.new()
		row.name = "%sRow" % slot_id.capitalize()
		var label := Label.new()
		label.text = SLOT_NAMES.get(slot_id, slot_id.capitalize())
		label.custom_minimum_size = Vector2(86, 24)
		var slot := ItemSlotScene.instantiate()
		slot.name = "%sSlot" % slot_id.capitalize()
		if slot.has_signal("slot_pressed"):
			slot.slot_pressed.connect(_on_slot_pressed.bind(slot_id))
		row.add_child(label)
		row.add_child(slot)
		slot_list.add_child(row)
		_slot_nodes[slot_id] = slot


func _on_slot_pressed(double_click: bool, slot_id: String) -> void:
	var slot: Control = _slot_nodes.get(slot_id, null)
	var item_id: String = slot.get_item_id() if slot != null else ""
	equip_slot_clicked.emit(slot_id, item_id, double_click)


func _update_stats(stats: Dictionary) -> void:
	var stats_label := get_node_or_null("StatsList") as Label
	if stats_label == null:
		return
	stats_label.text = "ATK %d\nDEF %d\nHP %d\nMP %d" % [
		int(stats.get("attack", 0)),
		int(stats.get("defense", 0)),
		int(stats.get("max_hp", 0)),
		int(stats.get("max_mp", 0)),
	]


func _ensure_panel_background() -> void:
	var fresh := not has_node("PanelBackground")
	UiTheme.add_panel_bg(self)
	if fresh:
		UiTheme.style_title(get_node_or_null("TitleLabel"), "装备")
		UiTheme.style_frame(get_node_or_null("PortraitFrame"))
		var stats := get_node_or_null("StatsList") as Label
		if stats != null:
			stats.add_theme_color_override("font_color", UiTheme.PARCHMENT)
