extends PanelContainer

var item_data: Dictionary = {}


func _ready() -> void:
	set_empty()


func set_empty() -> void:
	item_data = {}
	$QuantityLabel.text = ""
	$Icon.visible = false
	$SelectionFrame.visible = false
	set_meta("icon_index", -1)


func set_item(data: Dictionary) -> void:
	item_data = data.duplicate(true)
	$Icon.visible = true
	$SelectionFrame.visible = false
	set_meta("icon_index", int(item_data.get("icon_index", -1)))

	var quantity := int(item_data.get("quantity", 1))
	$QuantityLabel.text = str(quantity) if quantity > 1 else ""


func set_selected(value: bool) -> void:
	$SelectionFrame.visible = value


func get_item_id() -> String:
	return String(item_data.get("item_id", ""))
