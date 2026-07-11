extends SceneTree
# Verifies the cursor-carry item interaction coordinator in main.gd, driven at
# the logic level (no real mouse): pick up -> equip into the 5 equipment slots,
# assign a consumable to a quick slot and use it, double-click use/equip, the
# "unusable" hint for materials, and empty-area cancel leaving the model intact.
# Headless.
const MainScene := preload("res://scenes/main.tscn")
const DroppedItemScene := preload("res://scenes/loot/dropped_item.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame

	_give(main, "leather_cap", 1)
	_give(main, "copper_ring", 1)
	_give(main, "small_health_potion", 3)
	_give(main, "wolf_pelt", 1)

	# --- Pick up + place onto an equipment slot (helmet) --------------------
	main._on_inventory_slot_clicked(0, "leather_cap", false)
	if not main.is_carrying():
		failures.append("single-click should pick the item onto the cursor")
	main._on_equip_slot_clicked("helmet", "", false)
	if main.is_carrying():
		failures.append("placing on a compatible slot should clear the carry")
	if String(main._build_equipment_display().get("helmet", {}).get("item_id", "")) != "leather_cap":
		failures.append("leather_cap should be equipped in the helmet slot")

	# --- Wrong slot rejects the carried item, keeps carrying ----------------
	main._on_inventory_slot_clicked(0, "copper_ring", false)
	main._on_equip_slot_clicked("weapon", "", false)
	if not main.is_carrying():
		failures.append("dropping a ring on the weapon slot should not consume the carry")
	main._on_equip_slot_clicked("ring", "", false)
	if String(main._build_equipment_display().get("ring", {}).get("item_id", "")) != "copper_ring":
		failures.append("copper_ring should equip into the ring slot")

	# --- Assign a consumable to a quick slot, then use it via the key -------
	main._on_inventory_slot_clicked(0, "small_health_potion", false)
	main._on_quick_slot_clicked(2, false)
	if main.is_carrying():
		failures.append("assigning a consumable to a quick slot should clear the carry")
	if main._quick_items[2] != "small_health_potion":
		failures.append("quick slot 3 should reference small_health_potion")

	var player := main.get_node_or_null("Player")
	var hc := player.get_node_or_null("HealthComponent") if player != null else null
	if hc != null:
		hc.current_hp = 1
		var before: int = hc.current_hp
		var before_count: int = main._inventory.count_item("small_health_potion")
		main._use_quick_item(2)
		if hc.current_hp <= before:
			failures.append("using the quick-slot potion should heal the player")
		if main._inventory.count_item("small_health_potion") != before_count - 1:
			failures.append("using the quick-slot potion should consume one from the bag")

	# --- Double-click a material shows the unusable hint, no state change ----
	main._on_inventory_slot_clicked(0, "wolf_pelt", true)
	if main.is_carrying():
		failures.append("double-clicking an unusable item should not leave a carry")

	# --- Empty-area cancel returns the item without mutating the model -------
	var before_ids := _display_ids(main._build_inventory_display())
	main._on_inventory_slot_clicked(0, "copper_ring", false)
	main.cancel_carry()
	if main.is_carrying():
		failures.append("cancel_carry should clear the carry state")
	if _display_ids(main._build_inventory_display()) != before_ids:
		failures.append("cancelling a carry should leave the inventory unchanged")

	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("v08_item_interaction_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v08_item_interaction_test: FAIL")
	quit(1)


func _give(main: Node, item_id: String, quantity: int) -> void:
	main._inventory.add_item(item_id, quantity)
	main._refresh_ui()


func _display_ids(display: Array) -> Array:
	var ids: Array = []
	for entry in display:
		ids.append(String(entry.get("item_id", "")))
	return ids
