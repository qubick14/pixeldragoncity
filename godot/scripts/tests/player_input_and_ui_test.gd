extends SceneTree

const PlayerScene := preload("res://scenes/actors/player.tscn")
const MainScene := preload("res://scenes/main.tscn")
const GameDataScript := preload("res://scripts/data/game_data.gd")
const InventoryModelScript := preload("res://scripts/inventory/inventory_model.gd")
const EquipmentModelScript := preload("res://scripts/inventory/equipment_model.gd")
const StatCalculatorScript := preload("res://scripts/inventory/stat_calculator.gd")


func _initialize() -> void:
	var failures: Array[String] = []
	_test_mouse_move_modes(failures)
	_test_camera_zoom_and_visual_root(failures)
	_test_nine_direction_cells(failures)
	_test_walk_atlas_mapping(failures)
	_test_player_combat_nodes_and_attack(failures)
	_test_main_scene_hud(failures)
	await _test_hud_layout_and_debug_preview_defaults(failures)
	_test_menu_overlay_toggles(failures)
	_test_menu_overlay_model_binding(failures)
	await process_frame
	_test_viewport_size(failures)

	if failures.is_empty():
		print("player_input_and_ui_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_mouse_move_modes(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)

	player.start_pointer_move(Vector2(100, 0), false, false)
	_assert_equal(player.pointer_move_enabled, true, "left click should enable pointer movement", failures)
	_assert_equal(player.pointer_run_enabled, false, "left click should use walk speed", failures)
	_assert_equal(player.pointer_continuous_enabled, false, "single click should not be continuous", failures)
	_assert_equal(player.get_active_move_speed(), player.walk_speed, "walk move speed should be active after left click", failures)

	player.start_pointer_move(Vector2(200, 0), true, true)
	_assert_equal(player.pointer_run_enabled, true, "right hold should use run speed", failures)
	_assert_equal(player.pointer_continuous_enabled, true, "right hold should be continuous", failures)
	_assert_equal(player.get_active_move_speed(), player.run_speed, "run move speed should be active after right hold", failures)

	player.stop_pointer_move()
	_assert_equal(player.pointer_move_enabled, false, "stop pointer move should disable pointer movement", failures)

	player.queue_free()


func _test_camera_zoom_and_visual_root(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)

	var camera := player.get_node("Camera2D") as Camera2D
	_assert_equal(camera.zoom, Vector2(1.75, 1.75), "camera zoom should show a wider playable area", failures)
	_assert_equal(player.has_node("VisualRoot"), true, "player should have a VisualRoot for placeholder movement animation", failures)
	var visual_root := player.get_node("VisualRoot") as Node2D
	_assert_equal(visual_root.scale, Vector2(0.82, 0.82), "player visual scale should make the character smaller in the scene", failures)

	player.queue_free()


func _test_nine_direction_cells(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)

	var expected_cells := {
		Vector2(-1, -1): Vector2i(0, 0),
		Vector2(0, -1): Vector2i(1, 0),
		Vector2(1, -1): Vector2i(2, 0),
		Vector2(-1, 0): Vector2i(0, 1),
		Vector2.ZERO: Vector2i(1, 1),
		Vector2(1, 0): Vector2i(2, 1),
		Vector2(-1, 1): Vector2i(0, 2),
		Vector2(0, 1): Vector2i(1, 2),
		Vector2(1, 1): Vector2i(2, 2),
	}

	for direction in expected_cells:
		_assert_equal(player.get_direction_cell(direction), expected_cells[direction], "nine-direction cell should match input %s" % str(direction), failures)

	player.queue_free()


func _test_walk_atlas_mapping(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)

	_assert_equal(player.get_test_atlas_row(Vector2i(1, 2)), 0, "down should use front walk atlas row", failures)
	_assert_equal(player.get_test_atlas_row(Vector2i(0, 1)), 2, "left should use the v2 left-facing row", failures)
	_assert_equal(player.get_test_atlas_row(Vector2i(1, 0)), 4, "up should use the v2 back walk atlas row", failures)
	_assert_equal(player.get_test_atlas_row(Vector2i(2, 1)), 6, "right should use the v2 right-facing row", failures)
	_assert_equal(player.should_flip_test_atlas_row(Vector2i(2, 1)), false, "right should not mirror v2 source art", failures)
	_assert_equal(player.should_flip_test_atlas_row(Vector2i(0, 1)), false, "left should not mirror v2 source art", failures)
	_assert_equal(player.get_back_walk_frame_offset(Vector2i(1, 0), 2), Vector2.ZERO, "idle back view should not add a walk offset", failures)
	player.animation_state = player.AnimationState.WALK
	_assert_equal(player.get_back_walk_frame_offset(Vector2i(1, 0), 2), Vector2.ZERO, "v2 back-view walk should come from real frames, not offset compensation", failures)

	player.queue_free()


func _test_player_combat_nodes_and_attack(failures: Array[String]) -> void:
	var player := PlayerScene.instantiate()
	root.add_child(player)

	_assert_equal(player.has_node("HealthComponent"), true, "player should have a HealthComponent", failures)
	_assert_equal(player.has_node("Hurtbox"), true, "player should have a Hurtbox", failures)
	_assert_equal(player.has_node("AttackHitbox"), true, "player should have an AttackHitbox", failures)
	_assert_equal(InputMap.has_action("attack_primary"), true, "project should define attack_primary input", failures)

	if not player.has_node("AttackHitbox") or not player.has_method("start_attack"):
		failures.append("player should expose start_attack for melee combat")
		player.queue_free()
		return

	var attack_hitbox := player.get_node("AttackHitbox")
	_assert_equal(attack_hitbox.enabled, false, "player attack hitbox should be disabled by default", failures)
	_assert_equal(player.has_node("VisualRoot/AttackSlash"), true, "player should have a visible weapon slash node for attacks", failures)

	var first_attack_started: bool = player.start_attack()
	_assert_equal(first_attack_started, true, "start_attack should begin an attack when ready", failures)
	_assert_equal(attack_hitbox.enabled, true, "start_attack should enable the attack hitbox", failures)
	_assert_equal(player.AnimationState.has("ATTACK"), true, "player animation states should include a visible attack state", failures)
	if player.AnimationState.has("ATTACK"):
		_assert_equal(player.animation_state, player.AnimationState.ATTACK, "start_attack should enter a visible attack animation state", failures)
		_assert_equal((player.get_node("VisualRoot") as Node2D).position != Vector2.ZERO, true, "attack animation should visibly offset the player sprite", failures)
		player._update_generated_sprite_region()
		var attack_sprite := player.get_node("VisualRoot/GeneratedSprite") as Sprite2D
		_assert_equal(attack_sprite.texture.resource_path.ends_with("swordsman_attack_pixel_atlas.png"), true, "attack animation should swap to the attack atlas", failures)

	var second_attack_started: bool = player.start_attack()
	_assert_equal(second_attack_started, false, "attack cooldown should prevent immediate repeat attacks", failures)

	player.queue_free()


func _test_main_scene_hud(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)

	_assert_equal(main.has_node("HUD"), true, "main scene should instance the HUD", failures)
	var hud := main.get_node("HUD")
	_assert_equal(hud.has_method("set_health"), true, "HUD should expose set_health", failures)
	_assert_equal(hud.has_method("set_mana"), true, "HUD should expose set_mana", failures)
	_assert_equal(hud.has_method("set_experience"), true, "HUD should expose set_experience", failures)
	_assert_equal(hud.has_method("set_gold"), true, "HUD should expose set_gold", failures)
	_assert_equal(hud.has_method("set_level"), true, "HUD should expose set_level", failures)

	if hud.has_method("set_health"):
		hud.set_health(84, 100)
	if hud.has_method("set_mana"):
		hud.set_mana(32, 40)
	if hud.has_method("set_experience"):
		hud.set_experience(18, 100)
	if hud.has_method("set_gold"):
		hud.set_gold(128)
	if hud.has_method("set_level"):
		hud.set_level(1)

	var hp_row := main.get_node("HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/HpRow")
	var mp_row := main.get_node("HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/MpRow")
	var hp_bar := hp_row.get_node("HpBar") as ProgressBar
	var mp_bar := mp_row.get_node("MpBar") as ProgressBar
	_assert_equal(hp_row.get_node("HpValue").text, "84/100", "HUD should display health values", failures)
	_assert_equal(hp_bar.max_value, 100.0, "HUD health bar should track maximum health", failures)
	_assert_equal(hp_bar.value, 84.0, "HUD health bar should track current health", failures)
	_assert_equal(mp_row.get_node("MpValue").text, "32/40", "HUD should display mana values", failures)
	_assert_equal(mp_bar.max_value, 40.0, "HUD mana bar should track maximum mana", failures)
	_assert_equal(mp_bar.value, 32.0, "HUD mana bar should track current mana", failures)
	_assert_equal(main.get_node("HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/StatusLabel").text, "Lv.1  EXP 18%  Gold 128", "HUD should display level, EXP, and gold", failures)

	main.queue_free()


func _test_hud_layout_and_debug_preview_defaults(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)
	await process_frame

	var bottom_panel := main.get_node("HUD/LayoutRoot/BottomPanel") as Control
	var regions := main.get_node("HUD/LayoutRoot/BottomPanel/ContentMargin/Regions")
	var left_rect := (regions.get_node("LeftRegion") as Control).get_global_rect()
	var center_rect := (regions.get_node("CenterRegion") as Control).get_global_rect()
	var right_rect := (regions.get_node("RightRegion") as Control).get_global_rect()
	var bottom_rect := bottom_panel.get_global_rect()

	_assert_equal(bottom_panel.anchor_top, 1.0, "bottom panel should anchor from viewport bottom", failures)
	_assert_equal(bottom_panel.anchor_bottom, 1.0, "bottom panel should anchor to viewport bottom", failures)
	_assert_equal(absf(bottom_rect.size.y - 145.0) <= 2.0, true, "bottom panel height should remain approximately 145 pixels", failures)
	_assert_equal(bottom_rect.encloses(left_rect), true, "left HUD region should remain inside the bottom panel", failures)
	_assert_equal(bottom_rect.encloses(center_rect), true, "center HUD region should remain inside the bottom panel", failures)
	_assert_equal(bottom_rect.encloses(right_rect), true, "right HUD region should remain inside the bottom panel", failures)
	_assert_equal(left_rect.intersects(center_rect), false, "left and center HUD regions should not overlap", failures)
	_assert_equal(center_rect.intersects(right_rect), false, "center and right HUD regions should not overlap", failures)
	_assert_equal(left_rect.intersects(right_rect), false, "left and right HUD regions should not overlap", failures)

	var art_preview := main.get_node("ArtPreview") as CanvasLayer
	_assert_equal(art_preview.visible, false, "ArtPreview should be hidden by default outside debug review", failures)
	var character_portrait := main.get_node("HUD/LayoutRoot/CharacterPortrait") as TextureRect
	_assert_equal(character_portrait.visible, false, "HUD character portrait preview should be hidden during normal gameplay", failures)

	main.queue_free()


func _test_menu_overlay_toggles(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)

	var menu_overlay := _require_node(main, "MenuOverlay", "main scene should provide MenuOverlay", failures)
	var ui_root := _require_node(main, "UIRoot", "main scene should provide UIRoot", failures)
	var inventory_button := _require_button(
		main,
		"HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/MenuButtons/InventoryButton",
		"HUD should provide an inventory button",
		failures
	)
	var equipment_button := _require_button(
		main,
		"HUD/LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/MenuButtons/EquipmentButton",
		"HUD should provide an equipment button",
		failures
	)
	if menu_overlay == null or ui_root == null or inventory_button == null or equipment_button == null:
		main.queue_free()
		return

	var overlay_inventory := _require_node(menu_overlay, "InventoryPanel", "menu overlay should provide InventoryPanel", failures) as Control
	var overlay_equipment := _require_node(menu_overlay, "EquipmentPanel", "menu overlay should provide EquipmentPanel", failures) as Control
	var root_inventory := _require_node(ui_root, "InventoryPanel", "UIRoot should provide InventoryPanel", failures) as Control
	var root_equipment := _require_node(ui_root, "EquipmentPanel", "UIRoot should provide EquipmentPanel", failures) as Control
	if overlay_inventory == null or overlay_equipment == null or root_inventory == null or root_equipment == null:
		main.queue_free()
		return

	_assert_equal(menu_overlay.visible, false, "menu overlay should be hidden by default", failures)
	_assert_equal(ui_root.has_node("HUD"), false, "UIRoot should not include a duplicate HUD that steals mouse clicks from the main HUD", failures)

	inventory_button.pressed.emit()
	_assert_equal(menu_overlay.visible, true, "inventory button should show menu overlay", failures)
	_assert_equal(overlay_inventory.visible, true, "inventory button should show inventory panel", failures)
	_assert_equal(overlay_equipment.visible, false, "inventory button should hide equipment panel", failures)
	_assert_equal(root_inventory.visible, false, "inventory button should not show the UIRoot inventory panel", failures)
	inventory_button.pressed.emit()
	_assert_equal(menu_overlay.visible, false, "pressing inventory while inventory is open should close menu overlay", failures)
	inventory_button.pressed.emit()
	_assert_equal(menu_overlay.visible, true, "pressing inventory again should reopen menu overlay", failures)

	equipment_button.pressed.emit()
	_assert_equal(menu_overlay.visible, true, "equipment button should show menu overlay", failures)
	_assert_equal(overlay_inventory.visible, false, "equipment button should hide inventory panel", failures)
	_assert_equal(overlay_equipment.visible, true, "equipment button should show equipment panel", failures)
	_assert_equal(root_equipment.visible, false, "equipment button should not show the UIRoot equipment panel", failures)
	equipment_button.pressed.emit()
	_assert_equal(menu_overlay.visible, false, "pressing equipment while equipment is open should close menu overlay", failures)

	var close_button := _require_button(menu_overlay, "CloseButton", "menu overlay should provide a close button", failures)
	if close_button == null:
		main.queue_free()
		return
	equipment_button.pressed.emit()
	close_button.pressed.emit()
	_assert_equal(menu_overlay.visible, false, "close button should hide menu overlay", failures)
	for panel_name in ["InventoryPanel", "EquipmentPanel", "DialoguePanel", "ShopPanel"]:
		var panel := _require_node(ui_root, panel_name, "UIRoot should provide %s" % panel_name, failures) as Control
		if panel == null:
			continue
		_assert_equal(
			panel.visible,
			false,
			"close button should leave UIRoot %s hidden" % panel_name,
			failures
		)

	main.queue_free()


func _test_menu_overlay_model_binding(failures: Array[String]) -> void:
	var main := MainScene.instantiate()
	root.add_child(main)

	var game_data := GameDataScript.new()
	_assert_equal(game_data.load_all(), true, "menu test should load game data", failures)

	var inventory := InventoryModelScript.new()
	inventory.setup(game_data)
	inventory.add_gold(4)
	inventory.add_item("iron_sword", 1)

	var equipment := EquipmentModelScript.new()
	equipment.setup(game_data, inventory)
	equipment.equip("iron_sword")

	var stats := StatCalculatorScript.calculate({"attack": 1, "defense": 0, "max_hp": 100}, equipment, game_data)
	var menu_overlay := main.get_node("MenuOverlay")
	_assert_equal(menu_overlay.has_method("set_models"), true, "menu overlay should accept inventory and equipment models", failures)
	menu_overlay.set_models(inventory, equipment, game_data, stats)
	menu_overlay.show_inventory()
	_assert_equal(menu_overlay.get_node("InventoryPanel/InventoryListLabel").text.contains("Gold 4"), true, "inventory panel should show gold", failures)
	menu_overlay.show_equipment()
	_assert_equal(menu_overlay.get_node("EquipmentPanel/EquipmentListLabel").text.contains("Weapon: iron_sword"), true, "equipment panel should show equipped weapon", failures)
	_assert_equal(menu_overlay.get_node("EquipmentPanel/StatsLabel").text.contains("ATK 6"), true, "equipment panel should show calculated attack", failures)

	equipment.free()
	inventory.free()
	game_data.free()
	main.queue_free()


func _test_viewport_size(failures: Array[String]) -> void:
	var viewport_width := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
	var viewport_height := int(ProjectSettings.get_setting("display/window/size/viewport_height"))

	_assert_equal(viewport_width, 1600, "default viewport width should be wider for a larger game view", failures)
	_assert_equal(viewport_height, 900, "default viewport height should preserve 16:9 at a larger size", failures)


func _assert_equal(actual: Variant, expected: Variant, message: String, failures: Array[String]) -> void:
	if actual != expected:
		failures.append("%s. Expected %s, got %s" % [message, str(expected), str(actual)])


func _require_node(parent: Node, path: NodePath, message: String, failures: Array[String]) -> Node:
	var node := parent.get_node_or_null(path)
	if node == null:
		failures.append(message)
	return node


func _require_button(parent: Node, path: NodePath, message: String, failures: Array[String]) -> Button:
	var node := parent.get_node_or_null(path)
	if not node is Button:
		failures.append(message)
		return null
	return node as Button
