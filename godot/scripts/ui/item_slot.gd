extends PanelContainer

# Emitted on any left-click; double_click distinguishes use/equip (double) from pick-up (single).
signal slot_pressed(double_click: bool)

const ItemIconsSheet := preload("res://assets/items/item_icons_sheet.png")

var item_data: Dictionary = {}


func _ready() -> void:
	_apply_slot_style(false)
	set_empty()
	if not gui_input.is_connected(_on_gui_input):
		gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Report every left-click (even on empty slots) so the coordinator can place a carried item.
		slot_pressed.emit(event.double_click)
		accept_event()


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
	var icon_index := int(item_data.get("icon_index", -1))
	set_meta("icon_index", icon_index)
	_apply_icon(icon_index)
	$SelectionFrame.visible = false

	var quantity := int(item_data.get("quantity", 1))
	$QuantityLabel.text = str(quantity) if quantity > 1 else ""


func _apply_icon(icon_index: int) -> void:
	var icon := $Icon as TextureRect
	if icon_index < 0:
		icon.texture = null
		icon.visible = false
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = ItemIconsSheet
	atlas.region = Rect2(icon_index * 32, 0, 32, 32)
	icon.texture = atlas
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.visible = true


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
