extends Control

const ItemSlotScene := preload("res://scenes/ui/item_slot.tscn")

var _slots: Array[Control] = []

@onready var slot_grid: GridContainer = $SlotGrid


func set_inventory(slots: Array) -> void:
	_ensure_panel_background()
	_ensure_slots(slots.size())
	for index in range(_slots.size()):
		var slot := _slots[index]
		var data: Dictionary = slots[index] if index < slots.size() and slots[index] is Dictionary else {}
		if data.has("item_id"):
			slot.set_item(data)
		else:
			slot.set_empty()


func clear_slots() -> void:
	for slot in _slots:
		slot.set_empty()


func get_slot_count() -> int:
	return _slots.size()


func get_slot(index: int) -> Control:
	if index < 0 or index >= _slots.size():
		return null
	return _slots[index]


func _ensure_slots(count: int) -> void:
	_ensure_panel_background()
	if slot_grid == null:
		slot_grid = $SlotGrid
	while _slots.size() < count:
		var slot := ItemSlotScene.instantiate()
		slot.name = "Slot%d" % _slots.size()
		slot_grid.add_child(slot)
		_slots.append(slot)


func _ensure_panel_background() -> void:
	if has_node("PanelBackground"):
		return
	var background := ColorRect.new()
	background.name = "PanelBackground"
	background.color = Color(0.075, 0.055, 0.04, 0.92)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.offset_left = -16.0
	background.offset_top = -16.0
	background.offset_right = 16.0
	background.offset_bottom = 16.0
	add_child(background)
	move_child(background, 0)
