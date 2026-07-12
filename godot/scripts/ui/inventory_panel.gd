extends Control

signal slot_clicked(index: int, item_id: String, double_click: bool)

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
		var index := _slots.size()
		if slot.has_signal("slot_pressed"):
			slot.slot_pressed.connect(_on_slot_pressed.bind(index))
		_slots.append(slot)


func _on_slot_pressed(double_click: bool, index: int) -> void:
	var item_id := ""
	if index >= 0 and index < _slots.size():
		item_id = _slots[index].get_item_id()
	slot_clicked.emit(index, item_id, double_click)


func _ensure_panel_background() -> void:
	UiTheme.add_panel_bg(self)
	UiTheme.style_title(get_node_or_null("TitleLabel"), "背包")
