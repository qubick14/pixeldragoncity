extends Node2D

var menu_overlay: CanvasLayer
var ui_root: CanvasLayer
var inventory_button: Button
var equipment_button: Button


func _ready() -> void:
	menu_overlay = _get_menu_overlay()
	inventory_button = $"../HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/MenuButtons/InventoryButton"
	equipment_button = $"../HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/MenuButtons/EquipmentButton"

	if not inventory_button.pressed.is_connected(_on_inventory_button_pressed):
		inventory_button.pressed.connect(_on_inventory_button_pressed)
	if not equipment_button.pressed.is_connected(_on_equipment_button_pressed):
		equipment_button.pressed.connect(_on_equipment_button_pressed)
	var close_button := menu_overlay.get_node_or_null("CloseButton") as Button
	if close_button != null and not close_button.pressed.is_connected(_close_menus):
		close_button.pressed.connect(_close_menus)


func _on_inventory_button_pressed() -> void:
	var overlay := _get_menu_overlay()
	if _is_overlay_panel_open("InventoryPanel"):
		_close_menus()
		return

	_close_ui_root_panel()
	overlay.show_inventory()


func _on_equipment_button_pressed() -> void:
	var overlay := _get_menu_overlay()
	if _is_overlay_panel_open("EquipmentPanel"):
		_close_menus()
		return

	_close_ui_root_panel()
	overlay.show_equipment()


func _is_overlay_panel_open(panel_name: String) -> bool:
	var overlay := _get_menu_overlay()
	if not overlay.visible:
		return false
	var panel := overlay.get_node_or_null(panel_name) as Control
	return panel != null and panel.visible


func _close_menus() -> void:
	_close_ui_root_panel()
	_get_menu_overlay().hide_menu()


func _close_ui_root_panel() -> void:
	var root := _get_ui_root()
	if root != null and root.has_method("close_active_panel"):
		root.close_active_panel()


func _get_menu_overlay() -> CanvasLayer:
	if menu_overlay == null:
		menu_overlay = $"../MenuOverlay"
	return menu_overlay


func _get_ui_root() -> CanvasLayer:
	if ui_root == null:
		ui_root = get_node_or_null("../UIRoot") as CanvasLayer
	return ui_root
