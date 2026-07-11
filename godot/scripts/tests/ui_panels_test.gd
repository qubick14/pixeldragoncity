extends SceneTree

const ItemSlotScene := preload("res://scenes/ui/item_slot.tscn")
const ItemTooltipScene := preload("res://scenes/ui/item_tooltip.tscn")
const InventoryPanelScene := preload("res://scenes/ui/inventory_panel.tscn")
const EquipmentPanelScene := preload("res://scenes/ui/equipment_panel.tscn")
const DialoguePanelScene := preload("res://scenes/ui/dialogue_panel.tscn")
const ShopPanelScene := preload("res://scenes/ui/shop_panel.tscn")
const UIRootScene := preload("res://scenes/ui/ui_root.tscn")
const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_item_slot(failures)
	_test_item_tooltip(failures)
	_test_inventory_panel(failures)
	_test_equipment_panel(failures)
	_test_dialogue_panel(failures)
	_test_shop_panel(failures)
	_test_ui_root_routing(failures)
	await _test_map_npc_routes_to_ui_root(failures)

	if failures.is_empty():
		print("ui_panels_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_item_slot(failures: Array[String]) -> void:
	var slot := ItemSlotScene.instantiate()
	root.add_child(slot)

	slot.set_empty()
	_assert_equal(slot.get_item_id(), "", "empty slot should not expose an item id", failures)
	_assert_equal(slot.get_node("QuantityLabel").text, "", "empty slot should show no quantity text", failures)

	slot.set_item(_sample_item())
	_assert_equal(slot.get_item_id(), "small_health_potion", "filled slot should store item_id", failures)
	_assert_equal(slot.get_node("QuantityLabel").text, "3", "quantity greater than 1 should be displayed", failures)

	slot.set_selected(true)
	_assert_equal(slot.get_node("SelectionFrame").visible, true, "selected slot should show selection frame", failures)
	slot.set_selected(false)
	_assert_equal(slot.get_node("SelectionFrame").visible, false, "unselected slot should hide selection frame", failures)

	slot.queue_free()


func _test_item_tooltip(failures: Array[String]) -> void:
	var tooltip := ItemTooltipScene.instantiate()
	root.add_child(tooltip)

	tooltip.set_item(_sample_item())
	_assert_equal(tooltip.get_node("Content/NameLabel").text, "小型生命药水", "tooltip should show item name", failures)
	_assert_equal(tooltip.get_node("Content/QualityLabel").text, "common", "tooltip should show quality", failures)
	_assert_equal(tooltip.get_node("Content/DescriptionLabel").text.contains("恢复"), true, "tooltip should show description", failures)
	_assert_equal(tooltip.get_node("Content/PriceLabel").text, "Buy 8 / Sell 4", "tooltip should show price", failures)

	tooltip.hide_tooltip()
	_assert_equal(tooltip.visible, false, "hide_tooltip should hide the tooltip", failures)

	tooltip.queue_free()


func _test_inventory_panel(failures: Array[String]) -> void:
	var panel := InventoryPanelScene.instantiate()
	root.add_child(panel)

	panel.set_inventory(_sample_inventory_slots())
	_assert_equal(panel.get_slot_count(), 30, "inventory panel should render 30 slots", failures)
	_assert_equal(panel.get_node("TitleLabel").text, "Inventory", "inventory panel title should be Inventory", failures)
	_assert_equal(panel.get_slot(0).get_item_id(), "small_health_potion", "first inventory slot should expose filled item id", failures)
	_assert_equal(panel.get_slot(5).get_item_id(), "", "empty inventory slot should remain empty", failures)

	panel.queue_free()


func _test_equipment_panel(failures: Array[String]) -> void:
	var panel := EquipmentPanelScene.instantiate()
	root.add_child(panel)

	panel.set_equipment(_sample_equipment(), _sample_stats())
	_assert_equal(panel.get_equipment_slot("weapon").get_item_id(), "iron_sword", "weapon slot should show demo weapon", failures)
	_assert_equal(panel.get_equipment_slot("armor").get_item_id(), "leather_armor", "armor slot should show demo armor", failures)
	_assert_equal(panel.get_equipment_slot("helmet").get_item_id(), "", "helmet slot should exist and be empty", failures)
	_assert_equal(panel.has_node("PortraitFrame"), true, "equipment panel should include portrait region", failures)
	_assert_equal(panel.get_node("StatsList").text.contains("ATK 12"), true, "equipment stats should show attack", failures)
	_assert_equal(panel.get_node("StatsList").text.contains("DEF 4"), true, "equipment stats should show defense", failures)
	_assert_equal(panel.get_node("StatsList").text.contains("HP 100"), true, "equipment stats should show max_hp", failures)
	_assert_equal(panel.get_node("StatsList").text.contains("MP 40"), true, "equipment stats should show max_mp", failures)

	panel.queue_free()


func _test_dialogue_panel(failures: Array[String]) -> void:
	var panel := DialoguePanelScene.instantiate()
	root.add_child(panel)

	panel.start_dialogue(_sample_npc())
	_assert_equal(panel.get_node("NameLabel").text, "行商阿岚", "dialogue panel should show NPC name", failures)
	_assert_equal(panel.get_node("DialogueText").text, "背包要留几个空格。", "dialogue panel should show first line", failures)
	_assert_equal(panel.get_node("ShopButton").visible, true, "merchant dialogue should show shop button", failures)
	_assert_equal(panel.get_shop_id(), "merchant_general_store", "dialogue panel should expose shop id", failures)

	panel.advance()
	_assert_equal(panel.get_node("DialogueText").text, "我这里有药水和常用杂货。", "advance should move to second line", failures)
	panel.advance()
	_assert_equal(panel.is_finished(), true, "dialogue should finish after final line", failures)

	panel.queue_free()


func _test_shop_panel(failures: Array[String]) -> void:
	var panel := ShopPanelScene.instantiate()
	root.add_child(panel)

	var requested: Array[String] = []
	panel.buy_requested.connect(func(item_id: String) -> void: requested.append(item_id))
	panel.set_shop(_sample_shop(), 128)

	_assert_equal(panel.get_node("ShopNameLabel").text, "青木杂货铺", "shop panel should show shop name", failures)
	_assert_equal(panel.get_node("GoldLabel").text, "Gold 128", "shop panel should show player gold", failures)
	_assert_equal(panel.get_row_count(), 1, "shop panel should render item rows", failures)

	var first_row := panel.get_node("ItemList").get_child(0)
	_assert_equal(first_row.get_node("NameLabel").text, "小型生命药水", "shop row should show item display name", failures)
	_assert_equal(first_row.get_node("PriceLabel").text, "8", "shop row should show price", failures)
	first_row.get_node("BuyButton").pressed.emit()
	_assert_equal(requested.size(), 1, "buy button should emit buy request", failures)
	_assert_equal(requested[0], "small_health_potion", "buy request should include item_id", failures)

	panel.show_sell_tab()
	_assert_equal(panel.get_meta("active_tab"), "sell", "sell view should be selectable", failures)

	panel.queue_free()


func _test_ui_root_routing(failures: Array[String]) -> void:
	var ui_root := UIRootScene.instantiate()
	root.add_child(ui_root)

	_assert_equal(ui_root.has_node("HUD"), false, "UIRoot should not include a duplicate HUD because Main owns the clickable HUD", failures)
	ui_root.show_inventory()
	_assert_equal(ui_root.get_node("InventoryPanel").visible, true, "show_inventory should show inventory", failures)

	# Inventory and equipment are independent panels and may stay open together.
	ui_root.show_equipment()
	_assert_equal(ui_root.get_node("EquipmentPanel").visible, true, "show_equipment should show equipment", failures)
	_assert_equal(ui_root.get_node("InventoryPanel").visible, true, "equipment should not close inventory", failures)

	# Toggling one panel leaves the other untouched.
	ui_root.toggle_inventory()
	_assert_equal(ui_root.get_node("InventoryPanel").visible, false, "toggle_inventory should hide inventory", failures)
	_assert_equal(ui_root.get_node("EquipmentPanel").visible, true, "toggling inventory should leave equipment open", failures)
	ui_root.toggle_inventory()
	_assert_equal(ui_root.get_node("InventoryPanel").visible, true, "toggle_inventory should reopen inventory", failures)

	# Esc closes every open panel at once.
	ui_root.close_active_panel()
	_assert_equal(ui_root.get_node("InventoryPanel").visible, false, "close_active_panel should close inventory", failures)
	_assert_equal(ui_root.get_node("EquipmentPanel").visible, false, "close_active_panel should close equipment", failures)

	ui_root.show_dialogue("merchant")
	_assert_equal(ui_root.get_node("DialoguePanel").visible, true, "show_dialogue should show dialogue", failures)
	ui_root.get_node("DialoguePanel/ShopButton").pressed.emit()
	_assert_equal(ui_root.get_node("ShopPanel").visible, true, "merchant dialogue shop request should open shop", failures)

	ui_root.close_active_panel()
	_assert_equal(ui_root.get_node("ShopPanel").visible, false, "close_active_panel should hide active panel", failures)

	ui_root.queue_free()


func _test_map_npc_routes_to_ui_root(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	var map_manager := main.get_node("MapManager")
	var village: Node = map_manager.get_current_map()
	_assert_equal(village.has_node("Npcs/VillageChiefNpc"), true, "Greenwood Village should include VillageChiefNpc", failures)
	_assert_equal(village.has_node("Npcs/MerchantNpc"), true, "Greenwood Village should include MerchantNpc", failures)
	_assert_equal(village.has_node("Npcs/BlacksmithNpc"), true, "Greenwood Village should include BlacksmithNpc", failures)

	if not village.has_node("Npcs/VillageChiefNpc") or not village.has_node("Npcs/MerchantNpc") or not village.has_node("Npcs/BlacksmithNpc"):
		main.queue_free()
		return

	var quest_manager := main.get_node("QuestManager")
	var inventory_button := main.get_node(
		"HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/MenuButtons/InventoryButton"
	)
	inventory_button.pressed.emit()
	_assert_equal(main.get_node("MenuOverlay").visible, true, "HUD inventory button should open MenuOverlay", failures)

	var chief := village.get_node("Npcs/VillageChiefNpc")
	chief.interact()
	_assert_equal(main.get_node("MenuOverlay").visible, false, "village chief dialogue should close MenuOverlay", failures)
	_assert_equal(main.get_node("UIRoot/DialoguePanel").visible, true, "village chief interaction should open dialogue panel", failures)
	_assert_equal(main.get_node("UIRoot/DialoguePanel/NameLabel").text, "青木村长", "village chief dialogue should show chief name", failures)
	_assert_equal(quest_manager.get_quest_state("first_hunt"), "active", "village chief interaction should keep first_hunt quest behavior", failures)

	var merchant := village.get_node("Npcs/MerchantNpc")
	merchant.interact()
	_assert_equal(main.get_node("UIRoot/DialoguePanel").visible, true, "merchant interaction should open dialogue panel", failures)
	_assert_equal(main.get_node("UIRoot/DialoguePanel").get_shop_id(), "merchant_general_store", "merchant dialogue should link to general store", failures)

	main.get_node("UIRoot/DialoguePanel/ShopButton").pressed.emit()
	_assert_equal(main.get_node("UIRoot/ShopPanel").visible, true, "merchant shop button should open shop panel", failures)
	_assert_equal(main.get_node("UIRoot/ShopPanel/ShopNameLabel").text, "青木杂货铺", "merchant shop should show general store name", failures)

	var blacksmith := village.get_node("Npcs/BlacksmithNpc")
	blacksmith.interact()
	_assert_equal(main.get_node("UIRoot/DialoguePanel").visible, true, "blacksmith interaction should open dialogue panel", failures)
	_assert_equal(main.get_node("UIRoot/DialoguePanel").get_shop_id(), "blacksmith_basic_gear", "blacksmith dialogue should link to gear shop", failures)

	main.get_node("UIRoot/DialoguePanel/ShopButton").pressed.emit()
	_assert_equal(main.get_node("UIRoot/ShopPanel").visible, true, "blacksmith shop button should open shop panel", failures)
	_assert_equal(main.get_node("UIRoot/ShopPanel/ShopNameLabel").text, "石衡铁匠铺", "blacksmith shop should show gear store name", failures)

	main.queue_free()


func _sample_shop() -> Dictionary:
	return {
		"id": "merchant_general_store",
		"name": "青木杂货铺",
		"keeper_npc_id": "merchant",
		"items": [_sample_item()],
	}


func _sample_npc() -> Dictionary:
	return {
		"id": "merchant",
		"name": "行商阿岚",
		"portrait": "character_portrait_direction_v1",
		"dialogue": [
			"背包要留几个空格。",
			"我这里有药水和常用杂货。",
		],
		"shop_id": "merchant_general_store",
	}


func _sample_inventory_slots() -> Array:
	var slots: Array = []
	slots.append(_sample_item())
	for index in range(1, 30):
		slots.append({"slot": index})
	return slots


func _sample_equipment() -> Dictionary:
	return {
		"weapon": {
			"item_id": "iron_sword",
			"display_name": "铁剑",
			"kind": "weapon",
			"quality": "common",
			"quantity": 1,
			"price": 30,
			"sell_price": 12,
			"description": "比木剑更可靠的基础武器。",
			"icon_index": 1,
		},
		"armor": {
			"item_id": "leather_armor",
			"display_name": "皮甲",
			"kind": "armor",
			"quality": "uncommon",
			"quantity": 1,
			"price": 45,
			"sell_price": 18,
			"description": "轻便皮甲，提供基础防护和少量生命。",
			"icon_index": 3,
		},
		"helmet": {},
		"necklace": {},
		"ring": {},
	}


func _sample_stats() -> Dictionary:
	return {
		"attack": 12,
		"defense": 4,
		"max_hp": 100,
		"max_mp": 40,
	}


func _sample_item() -> Dictionary:
	return {
		"item_id": "small_health_potion",
		"display_name": "小型生命药水",
		"kind": "consumable",
		"quality": "common",
		"quantity": 3,
		"price": 8,
		"sell_price": 4,
		"description": "恢复少量生命，适合新手在野外保命。",
		"icon_index": 4,
	}


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])
