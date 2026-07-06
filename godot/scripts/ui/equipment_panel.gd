extends Control

const ItemSlotScene := preload("res://scenes/ui/item_slot.tscn")
const EQUIPMENT_SLOTS := ["weapon", "armor", "helmet", "necklace", "ring"]

var _slot_nodes: Dictionary = {}


func _ready() -> void:
	_ensure_slots()


func set_equipment(equipment: Dictionary, stats: Dictionary) -> void:
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
	var slot_list := get_node_or_null("SlotList") as VBoxContainer
	if slot_list == null:
		return
	for slot_id in EQUIPMENT_SLOTS:
		if _slot_nodes.has(slot_id):
			continue
		var row := HBoxContainer.new()
		row.name = "%sRow" % slot_id.capitalize()
		var label := Label.new()
		label.text = slot_id.capitalize()
		label.custom_minimum_size = Vector2(86, 24)
		var slot := ItemSlotScene.instantiate()
		slot.name = "%sSlot" % slot_id.capitalize()
		row.add_child(label)
		row.add_child(slot)
		slot_list.add_child(row)
		_slot_nodes[slot_id] = slot


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
