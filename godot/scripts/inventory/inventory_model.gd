extends Node

var gold: int = 0

var _game_data: Node = null
var _entries: Array[Dictionary] = []


func setup(game_data_ref: Node) -> void:
	_game_data = game_data_ref
	gold = 0
	_entries.clear()


func add_gold(amount: int) -> void:
	gold += max(0, amount)


func spend_gold(amount: int) -> bool:
	if amount < 0 or amount > gold:
		return false
	gold -= amount
	return true


func add_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or not _has_item(item_id):
		return false

	var rules: Dictionary = _game_data.get_item_stack_rules(item_id)
	if not bool(rules.get("stackable", false)):
		for _i in range(quantity):
			_entries.append({"item_id": item_id, "quantity": 1})
		return true

	var remaining := quantity
	var max_stack := maxi(1, int(rules.get("max_stack", 99)))
	for entry in _entries:
		if entry.get("item_id") != item_id:
			continue
		var space := max_stack - int(entry.get("quantity", 0))
		if space <= 0:
			continue
		var added := mini(space, remaining)
		entry["quantity"] = int(entry.get("quantity", 0)) + added
		remaining -= added
		if remaining == 0:
			return true

	while remaining > 0:
		var stack_quantity := mini(max_stack, remaining)
		_entries.append({"item_id": item_id, "quantity": stack_quantity})
		remaining -= stack_quantity
	return true


func remove_item(item_id: String, quantity: int = 1) -> bool:
	if quantity <= 0 or count_item(item_id) < quantity:
		return false

	var remaining := quantity
	for index in range(_entries.size() - 1, -1, -1):
		var entry: Dictionary = _entries[index]
		if entry.get("item_id") != item_id:
			continue

		var entry_quantity := int(entry.get("quantity", 0))
		if entry_quantity <= remaining:
			remaining -= entry_quantity
			_entries.remove_at(index)
		else:
			entry["quantity"] = entry_quantity - remaining
			remaining = 0

		if remaining == 0:
			return true
	return true


func count_item(item_id: String) -> int:
	var total := 0
	for entry in _entries:
		if entry.get("item_id") == item_id:
			total += int(entry.get("quantity", 0))
	return total


func get_entries() -> Array:
	return _entries.duplicate(true)


func is_equipment(item_id: String) -> bool:
	return _has_item(item_id) and not _game_data.get_item_slot(item_id).is_empty()


func take_first_equipment(item_id: String) -> bool:
	if not is_equipment(item_id):
		return false
	return remove_item(item_id, 1)


func _has_item(item_id: String) -> bool:
	return _game_data != null and _game_data.has_method("has_item") and _game_data.has_item(item_id)
