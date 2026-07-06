extends Node2D

var menu_overlay: CanvasLayer
var ui_root: CanvasLayer
var inventory_button: Button
var equipment_button: Button


func _ready() -> void:
	menu_overlay = _get_menu_overlay()
	inventory_button = $"../HUD/BottomPanel/MenuButtons/InventoryButton"
	equipment_button = $"../HUD/BottomPanel/MenuButtons/EquipmentButton"

	if not inventory_button.pressed.is_connected(_on_inventory_button_pressed):
		inventory_button.pressed.connect(_on_inventory_button_pressed)
	if not equipment_button.pressed.is_connected(_on_equipment_button_pressed):
		equipment_button.pressed.connect(_on_equipment_button_pressed)


func _on_inventory_button_pressed() -> void:
	var root := _get_ui_root()
	if root != null and root.has_method("show_inventory"):
		root.show_inventory()
	_get_menu_overlay().show_inventory()


func _on_equipment_button_pressed() -> void:
	var root := _get_ui_root()
	if root != null and root.has_method("show_equipment"):
		root.show_equipment()
	_get_menu_overlay().show_equipment()


func _get_menu_overlay() -> CanvasLayer:
	if menu_overlay == null:
		menu_overlay = $"../MenuOverlay"
	return menu_overlay


func _get_ui_root() -> CanvasLayer:
	if ui_root == null:
		ui_root = get_node_or_null("../UIRoot") as CanvasLayer
	return ui_root
