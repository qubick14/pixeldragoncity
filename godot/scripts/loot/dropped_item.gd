extends Area2D

var _payload: Dictionary = {}


func _ready() -> void:
	add_to_group("dropped_item")
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func setup_item(item_id: String, quantity: int) -> void:
	_payload = {
		"kind": "item",
		"item_id": item_id,
		"quantity": maxi(1, quantity),
	}
	_apply_icon(_lookup_icon_index(item_id))


func setup_gold(amount: int) -> void:
	_payload = {
		"kind": "gold",
		"amount": maxi(1, amount),
	}
	_apply_icon(6)  # coin icon


func get_payload() -> Dictionary:
	return _payload.duplicate(true)


func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	var session := get_tree().get_first_node_in_group("game_session")
	if session != null and session.has_method("collect_drop"):
		session.collect_drop(self)


func _apply_icon(icon_index: int) -> void:
	var icon := get_node_or_null("Icon") as Sprite2D
	if icon == null:
		return
	icon.region_rect = Rect2(icon_index * 32, 0, 32, 32)


func _lookup_icon_index(item_id: String) -> int:
	var session := get_tree().get_first_node_in_group("game_session")
	if session != null and session.has_method("get_item_icon_index"):
		return session.get_item_icon_index(item_id)
	return 0


func pickup(inventory_model: Node) -> bool:
	match String(_payload.get("kind", "")):
		"item":
			var added: bool = inventory_model.add_item(String(_payload.get("item_id", "")), int(_payload.get("quantity", 0)))
			if added:
				queue_free()
			return added
		"gold":
			inventory_model.add_gold(int(_payload.get("amount", 0)))
			queue_free()
			return true
		_:
			return false
