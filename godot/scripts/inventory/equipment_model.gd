extends Node

var _game_data: Node = null
var _inventory: Node = null
var _slots: Dictionary = {
	"weapon": "",
	"armor": "",
	"helmet": "",
	"necklace": "",
	"ring": "",
}


func setup(game_data_ref: Node, inventory_ref: Node) -> void:
	_game_data = game_data_ref
	_inventory = inventory_ref
	_slots = {
		"weapon": "",
		"armor": "",
		"helmet": "",
		"necklace": "",
		"ring": "",
	}


func equip(item_id: String) -> bool:
	if _game_data == null or _inventory == null:
		return false
	if not _inventory.has_method("count_item") or _inventory.count_item(item_id) <= 0:
		return false

	var slot: String = get_slot_for_item(item_id)
	if slot.is_empty():
		return false

	if not _inventory.take_first_equipment(item_id):
		return false

	var previous: String = get_equipped_item_id(slot)
	if not previous.is_empty():
		_inventory.add_item(previous, 1)

	_slots[slot] = item_id
	return true


func unequip(slot: String) -> bool:
	if _inventory == null or not _slots.has(slot):
		return false

	var previous: String = get_equipped_item_id(slot)
	if previous.is_empty():
		return false

	_slots[slot] = ""
	return _inventory.add_item(previous, 1)


func get_equipped_item_id(slot: String) -> String:
	return String(_slots.get(slot, ""))


func get_equipped_items() -> Dictionary:
	return _slots.duplicate(true)


func get_slots() -> Dictionary:
	return _slots.duplicate(true)


func get_slot_for_item(item_id: String) -> String:
	if _game_data == null or not _game_data.has_item(item_id):
		return ""
	var slot: String = _game_data.get_item_slot(item_id)
	if _slots.has(slot):
		return slot
	return ""
