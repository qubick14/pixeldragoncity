extends Control

signal buy_requested(item_id: String)
signal shop_closed

const ShopItemRowScene := preload("res://scenes/ui/shop_item_row.tscn")

var _shop_data: Dictionary = {}
var _player_gold: int = 0


func _ready() -> void:
	$BuyTabButton.pressed.connect(show_buy_tab)
	$SellTabButton.pressed.connect(show_sell_tab)
	$CloseButton.pressed.connect(_close_shop)
	visible = false


func set_shop(shop_data: Dictionary, player_gold: int) -> void:
	visible = true
	_shop_data = shop_data.duplicate(true)
	_player_gold = player_gold
	$ShopNameLabel.text = String(_shop_data.get("name", ""))
	$GoldLabel.text = "Gold %d" % _player_gold
	show_buy_tab()


func show_buy_tab() -> void:
	set_meta("active_tab", "buy")
	_clear_rows()
	var items: Array = _shop_data.get("items", []) as Array
	for item in items:
		if item is Dictionary:
			_add_row(item)


func show_sell_tab() -> void:
	set_meta("active_tab", "sell")
	_clear_rows()


func get_row_count() -> int:
	return $ItemList.get_child_count()


func _add_row(item_data: Dictionary) -> void:
	var row := ShopItemRowScene.instantiate()
	row.set_item(item_data)
	row.buy_requested.connect(func(item_id: String) -> void: buy_requested.emit(item_id))
	$ItemList.add_child(row)


func _clear_rows() -> void:
	for child in $ItemList.get_children():
		child.queue_free()


func _close_shop() -> void:
	visible = false
	shop_closed.emit()
