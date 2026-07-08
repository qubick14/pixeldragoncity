extends PanelContainer

var item_data: Dictionary = {}


func _ready() -> void:
	_apply_slot_style(false)
	set_empty()


func set_empty() -> void:
	item_data = {}
	_apply_slot_style(false)
	$QuantityLabel.text = ""
	$Icon.visible = false
	$SelectionFrame.visible = false
	set_meta("icon_index", -1)


func set_item(data: Dictionary) -> void:
	item_data = data.duplicate(true)
	_apply_slot_style(true)
	$Icon.visible = true
	$SelectionFrame.visible = false
	set_meta("icon_index", int(item_data.get("icon_index", -1)))

	var quantity := int(item_data.get("quantity", 1))
	$QuantityLabel.text = str(quantity) if quantity > 1 else ""


func set_selected(value: bool) -> void:
	$SelectionFrame.visible = value


func get_item_id() -> String:
	return String(item_data.get("item_id", ""))


func _apply_slot_style(filled: bool) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.12, 0.08, 0.94) if filled else Color(0.08, 0.065, 0.05, 0.92)
	style.border_color = Color(0.62, 0.42, 0.18, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	add_theme_stylebox_override("panel", style)
