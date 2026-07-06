extends SceneTree

const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	var loader := JsonDataLoader.new()

	var npcs: Variant = loader.load_json("res://../data/npcs.json")
	var shops: Variant = loader.load_json("res://../data/shops.json")
	var demo_state: Variant = loader.load_json("res://../data/ui_demo_state.json")

	_assert_equal(npcs is Array, true, "npcs data should load as an Array", failures)
	_assert_equal(shops is Array, true, "shops data should load as an Array", failures)
	_assert_equal(demo_state is Dictionary, true, "demo state should load as a Dictionary", failures)

	if npcs is Array:
		_assert_equal(_array_has_id(npcs, "village_chief"), true, "NPC ids should include village_chief", failures)
		_assert_equal(_array_has_id(npcs, "merchant"), true, "NPC ids should include merchant", failures)
		_assert_equal(_array_has_id(npcs, "blacksmith"), true, "NPC ids should include blacksmith", failures)
		var merchant := _get_by_id(npcs, "merchant")
		_assert_equal(merchant.get("shop_id", ""), "merchant_general_store", "merchant should link to general store", failures)

	if shops is Array:
		_assert_equal(_array_has_id(shops, "merchant_general_store"), true, "shops should include merchant_general_store", failures)

	if demo_state is Dictionary:
		var inventory: Array = demo_state.get("inventory", []) as Array
		var player: Dictionary = demo_state.get("player", {}) as Dictionary
		_assert_equal(inventory.size(), 30, "demo inventory should include 30 slots", failures)
		_assert_equal(player.get("gold", -1), 128, "demo state gold should equal 128", failures)

	if failures.is_empty():
		print("ui_data_load_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _array_has_id(items: Array, id: String) -> bool:
	return not _get_by_id(items, id).is_empty()


func _get_by_id(items: Array, id: String) -> Dictionary:
	for item in items:
		if item is Dictionary and item.get("id", "") == id:
			return item
	return {}


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
