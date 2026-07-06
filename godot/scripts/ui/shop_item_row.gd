extends HBoxContainer

signal buy_requested(item_id: String)

var _item_id: String = ""


func _ready() -> void:
	_ensure_button_signal()


func set_item(data: Dictionary) -> void:
	_ensure_button_signal()
	_item_id = String(data.get("item_id", ""))
	$NameLabel.text = String(data.get("display_name", _item_id))
	$KindLabel.text = String(data.get("kind", ""))
	$PriceLabel.text = str(int(data.get("price", 0)))
	set_meta("item_data", data.duplicate(true))


func get_item_id() -> String:
	return _item_id


func _emit_buy_requested() -> void:
	buy_requested.emit(_item_id)


func _ensure_button_signal() -> void:
	var buy_button := get_node_or_null("BuyButton") as Button
	if buy_button != null and not buy_button.pressed.is_connected(_emit_buy_requested):
		buy_button.pressed.connect(_emit_buy_requested)
