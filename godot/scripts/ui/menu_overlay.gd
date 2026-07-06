extends CanvasLayer

var inventory_panel: Control
var equipment_panel: Control
var close_button: Button
var inventory_list_label: Label
var equipment_list_label: Label
var stats_label: Label


func _ready() -> void:
	_ensure_labels()
	inventory_panel = _get_inventory_panel()
	equipment_panel = _get_equipment_panel()
	close_button = $CloseButton
	if not close_button.pressed.is_connected(hide_menu):
		close_button.pressed.connect(hide_menu)
	hide_menu()


func show_inventory() -> void:
	visible = true
	_get_inventory_panel().visible = true
	_get_equipment_panel().visible = false


func show_equipment() -> void:
	visible = true
	_get_inventory_panel().visible = false
	_get_equipment_panel().visible = true


func hide_menu() -> void:
	visible = false


func set_models(inventory_model: Node, equipment_model: Node, _game_data_ref: Node, calculated_stats: Dictionary) -> void:
	_ensure_labels()
	_update_inventory_label(inventory_model)
	_update_equipment_label(equipment_model)
	_update_stats_label(calculated_stats)


func _get_inventory_panel() -> Control:
	if inventory_panel == null:
		inventory_panel = $InventoryPanel
	return inventory_panel


func _get_equipment_panel() -> Control:
	if equipment_panel == null:
		equipment_panel = $EquipmentPanel
	return equipment_panel


func _update_inventory_label(inventory_model: Node) -> void:
	_ensure_labels()
	if inventory_list_label == null:
		return
	var lines: Array[String] = ["Gold %d" % int(inventory_model.gold)]
	for entry in inventory_model.get_entries():
		lines.append("%s x%d" % [String(entry.get("item_id", "")), int(entry.get("quantity", 0))])
	inventory_list_label.text = "\n".join(lines)


func _update_equipment_label(equipment_model: Node) -> void:
	_ensure_labels()
	if equipment_list_label == null:
		return
	var weapon: String = equipment_model.get_equipped_item_id("weapon")
	var armor: String = equipment_model.get_equipped_item_id("armor")
	equipment_list_label.text = "Weapon: %s\nArmor: %s" % [weapon, armor]


func _update_stats_label(calculated_stats: Dictionary) -> void:
	_ensure_labels()
	if stats_label == null:
		return
	stats_label.text = "ATK %d\nDEF %d\nHP %d" % [
		int(calculated_stats.get("attack", 0)),
		int(calculated_stats.get("defense", 0)),
		int(calculated_stats.get("max_hp", 0)),
	]


func _ensure_labels() -> void:
	if inventory_list_label == null:
		inventory_list_label = get_node_or_null("InventoryPanel/InventoryListLabel") as Label
	if equipment_list_label == null:
		equipment_list_label = get_node_or_null("EquipmentPanel/EquipmentListLabel") as Label
	if stats_label == null:
		stats_label = get_node_or_null("EquipmentPanel/StatsLabel") as Label
