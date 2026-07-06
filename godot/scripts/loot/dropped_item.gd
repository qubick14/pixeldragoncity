extends Area2D

var _payload: Dictionary = {}


func setup_item(item_id: String, quantity: int) -> void:
	_payload = {
		"kind": "item",
		"item_id": item_id,
		"quantity": maxi(1, quantity),
	}


func setup_gold(amount: int) -> void:
	_payload = {
		"kind": "gold",
		"amount": maxi(1, amount),
	}


func get_payload() -> Dictionary:
	return _payload.duplicate(true)


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
