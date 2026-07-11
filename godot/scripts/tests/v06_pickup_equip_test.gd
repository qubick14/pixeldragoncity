extends SceneTree
# Verifies the live runtime loop wired in main.gd: a dropped item can be
# collected into the live inventory, appears in the inventory display, and
# equipping it changes the player's stats. Headless.
const MainScene := preload("res://scenes/main.tscn")
const DroppedItemScene := preload("res://scenes/loot/dropped_item.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(6):
		await process_frame

	# Drop a piece of equipment and collect it via the session glue.
	var drop := DroppedItemScene.instantiate()
	main.add_child(drop)
	drop.setup_item("leather_armor", 1)
	var collected: bool = main.collect_drop(drop)
	if not collected:
		failures.append("collect_drop returned false")

	var inv_ids := _display_ids(main._build_inventory_display())
	if not inv_ids.has("leather_armor"):
		failures.append("picked-up leather_armor not in inventory display: %s" % str(inv_ids))
	if not inv_ids.has("wooden_sword"):
		failures.append("starting wooden_sword missing from inventory: %s" % str(inv_ids))

	var base_defense: int = int(main._build_stats().get("defense", 0))

	# Equip the armor -> defense should rise by leather_armor's +3.
	main._use_or_equip("leather_armor")
	var new_defense: int = int(main._build_stats().get("defense", 0))
	if new_defense != base_defense + 3:
		failures.append("defense after equip expected %d, got %d" % [base_defense + 3, new_defense])

	var equipped: Dictionary = main._build_equipment_display()
	var armor_slot: Dictionary = equipped.get("armor", {})
	if String(armor_slot.get("item_id", "")) != "leather_armor":
		failures.append("armor slot not showing leather_armor: %s" % str(equipped))

	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("v06_pickup_equip_test: PASS")
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	print("v06_pickup_equip_test: FAIL")
	quit(1)


func _display_ids(display: Array) -> Array:
	var ids: Array = []
	for entry in display:
		ids.append(String(entry.get("item_id", "")))
	return ids
