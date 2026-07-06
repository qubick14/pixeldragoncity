extends SceneTree

const GameDataScript := preload("res://scripts/data/game_data.gd")
const InventoryModelScript := preload("res://scripts/inventory/inventory_model.gd")
const EquipmentModelScript := preload("res://scripts/inventory/equipment_model.gd")
const StatCalculatorScript := preload("res://scripts/inventory/stat_calculator.gd")
const LootTableScript := preload("res://scripts/loot/loot_table.gd")
const DroppedItemScene := preload("res://scenes/loot/dropped_item.tscn")

const PLAYER_BASE_STATS := {
	"attack": 1,
	"magic_attack": 0,
	"defense": 0,
	"max_hp": 100,
	"max_mp": 30,
	"speed": 140,
	"crit_rate": 0.0,
}


func _initialize() -> void:
	var failures: Array[String] = []
	var game_data := _test_game_data(failures)
	var inventory := _test_inventory_model(game_data, failures)
	var equipment := _test_equipment_and_stats(game_data, inventory, failures)
	_test_loot_table(game_data, failures)
	await _test_dropped_item_payload(game_data, failures)

	if equipment == null:
		failures.append("equipment model should be available for v0.3 tests")

	if equipment != null:
		equipment.free()
	if inventory != null:
		inventory.free()
	if game_data != null:
		game_data.free()
	await process_frame

	if failures.is_empty():
		print("v0_3_inventory_and_loot_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_game_data(failures: Array[String]) -> Node:
	var game_data := GameDataScript.new()
	_assert_equal(game_data.load_all(), true, "GameData should load items and monsters", failures)
	_assert_equal(game_data.get_item("iron_sword").get("name"), "铁剑", "GameData should load iron sword", failures)
	_assert_equal(game_data.get_item("leather_armor").get("stats", {}).get("max_hp"), 15, "GameData should load leather armor max HP", failures)
	_assert_equal(game_data.get_monster("wild_wolf").get("gold"), 4, "GameData should load wild wolf gold", failures)
	_assert_equal(game_data.get_monster("black_wolf_leader").get("drops", []).size(), 3, "GameData should load black wolf leader drops", failures)
	_assert_equal(game_data.has_item("missing_item"), false, "GameData should return false for missing items", failures)
	_assert_equal(game_data.validate_monster_drops().is_empty(), true, "monster drops should reference known item ids", failures)
	return game_data


func _test_inventory_model(game_data: Node, failures: Array[String]) -> Node:
	var inventory := InventoryModelScript.new()
	inventory.setup(game_data)
	_assert_equal(inventory.gold, 0, "new inventory should start with 0 gold", failures)
	_assert_equal(inventory.get_entries().size(), 0, "new inventory should start empty", failures)

	inventory.add_gold(4)
	_assert_equal(inventory.gold, 4, "adding gold should increase inventory gold", failures)

	_assert_equal(inventory.add_item("wolf_pelt", 2), true, "adding wolf pelts should succeed", failures)
	_assert_equal(inventory.count_item("wolf_pelt"), 2, "wolf pelts should count as 2", failures)
	_assert_equal(inventory.add_item("wolf_pelt", 1), true, "adding another wolf pelt should succeed", failures)
	_assert_equal(inventory.count_item("wolf_pelt"), 3, "wolf pelts should stack to 3", failures)

	_assert_equal(inventory.add_item("iron_sword", 1), true, "adding first iron sword should succeed", failures)
	_assert_equal(inventory.add_item("iron_sword", 1), true, "adding second iron sword should succeed", failures)
	_assert_equal(inventory.count_item("iron_sword"), 2, "equipment items should remain countable as separate entries", failures)

	_assert_equal(inventory.remove_item("wolf_pelt", 1), true, "removing an available wolf pelt should succeed", failures)
	_assert_equal(inventory.count_item("wolf_pelt"), 2, "wolf pelt count should decrease after removal", failures)
	_assert_equal(inventory.remove_item("wolf_pelt", 99), false, "removing unavailable quantity should fail", failures)
	_assert_equal(inventory.count_item("wolf_pelt"), 2, "failed removal should leave inventory unchanged", failures)
	return inventory


func _test_equipment_and_stats(game_data: Node, inventory: Node, failures: Array[String]) -> Node:
	var equipment := EquipmentModelScript.new()
	equipment.setup(game_data, inventory)
	_assert_equal(equipment.get_equipped_item_id("weapon"), "", "weapon slot should start empty", failures)
	_assert_equal(equipment.get_equipped_item_id("armor"), "", "armor slot should start empty", failures)

	_assert_equal(equipment.equip("iron_sword"), true, "equipping iron sword should succeed", failures)
	_assert_equal(equipment.get_equipped_item_id("weapon"), "iron_sword", "weapon slot should hold iron sword", failures)
	_assert_equal(inventory.count_item("iron_sword"), 1, "equipping iron sword should remove one from inventory", failures)

	_assert_equal(inventory.add_item("leather_armor", 1), true, "adding leather armor should succeed", failures)
	_assert_equal(equipment.equip("leather_armor"), true, "equipping leather armor should succeed", failures)
	_assert_equal(equipment.get_equipped_item_id("armor"), "leather_armor", "armor slot should hold leather armor", failures)

	var stats: Dictionary = StatCalculatorScript.calculate(PLAYER_BASE_STATS, equipment, game_data)
	_assert_equal(stats.get("attack"), 6, "iron sword should increase attack to 6", failures)
	_assert_equal(stats.get("defense"), 3, "leather armor should increase defense to 3", failures)
	_assert_equal(stats.get("max_hp"), 115, "leather armor should increase max HP to 115", failures)
	_assert_equal(stats.has("crit_rate"), true, "calculated stats should include crit_rate", failures)

	_assert_equal(inventory.add_item("wooden_sword", 1), true, "adding wooden sword should succeed", failures)
	_assert_equal(equipment.equip("wooden_sword"), true, "equipping wooden sword should replace iron sword", failures)
	_assert_equal(equipment.get_equipped_item_id("weapon"), "wooden_sword", "weapon slot should hold wooden sword after replacement", failures)
	_assert_equal(inventory.count_item("iron_sword"), 2, "replaced iron sword should return to inventory", failures)
	_assert_equal(equipment.equip("wolf_pelt"), false, "non-equipment items should not equip", failures)
	return equipment


func _test_loot_table(game_data: Node, failures: Array[String]) -> void:
	var loot_table := LootTableScript.new()
	loot_table.setup(game_data)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var boss_loot: Array = loot_table.roll("black_wolf_leader", rng)
	_assert_equal(_loot_amount(boss_loot, "gold", ""), 30, "black wolf leader should drop 30 gold", failures)
	_assert_equal(_loot_amount(boss_loot, "item", "leather_armor"), 1, "black wolf leader should always drop leather armor", failures)
	var pelt_count := _loot_amount(boss_loot, "item", "wolf_pelt")
	if pelt_count < 3 or pelt_count > 6:
		failures.append("black wolf leader should drop 3 to 6 wolf pelts, got %s" % pelt_count)

	var wolf_loot: Array = loot_table.roll("wild_wolf", rng)
	_assert_equal(_loot_amount(wolf_loot, "gold", ""), 4, "wild wolf should drop 4 gold", failures)
	_assert_equal(loot_table.roll("missing_monster", rng).is_empty(), true, "unknown monster should return empty loot", failures)
	loot_table.free()


func _test_dropped_item_payload(game_data: Node, failures: Array[String]) -> void:
	var inventory := InventoryModelScript.new()
	inventory.setup(game_data)

	var item_drop := DroppedItemScene.instantiate()
	root.add_child(item_drop)
	item_drop.setup_item("wolf_pelt", 2)
	_assert_equal(item_drop.get_payload(), {"kind": "item", "item_id": "wolf_pelt", "quantity": 2}, "dropped item should store item payload", failures)
	_assert_equal(item_drop.pickup(inventory), true, "item pickup should add to inventory", failures)
	_assert_equal(inventory.count_item("wolf_pelt"), 2, "picked up wolf pelts should enter inventory", failures)
	item_drop.queue_free()

	var gold_drop := DroppedItemScene.instantiate()
	root.add_child(gold_drop)
	gold_drop.setup_gold(4)
	_assert_equal(gold_drop.get_payload(), {"kind": "gold", "amount": 4}, "dropped item should store gold payload", failures)
	_assert_equal(gold_drop.pickup(inventory), true, "gold pickup should add to inventory", failures)
	_assert_equal(inventory.gold, 4, "picked up gold should enter inventory", failures)
	inventory.free()
	await process_frame


func _loot_amount(loot: Array, kind: String, item_id: String) -> int:
	var total := 0
	for entry in loot:
		if entry.get("kind") != kind:
			continue
		if kind == "item" and entry.get("item_id") != item_id:
			continue
		total += int(entry.get("quantity", entry.get("amount", 0)))
	return total


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
