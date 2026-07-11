extends SceneTree

const HudScene := preload("res://scenes/ui/hud.tscn")
const VIEWPORT_SIZES: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1498, 843),
]


func _initialize() -> void:
	var failures: Array[String] = []

	for viewport_size in VIEWPORT_SIZES:
		await _test_hud_at_size(viewport_size, failures)

	if failures.is_empty():
		print("hud_responsive_layout_test: PASS")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _test_hud_at_size(viewport_size: Vector2i, failures: Array[String]) -> void:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	viewport.disable_3d = true
	root.add_child(viewport)

	var hud := HudScene.instantiate()
	viewport.add_child(hud)

	for _frame in range(3):
		await process_frame

	var context := "%dx%d" % [viewport_size.x, viewport_size.y]
	_expect(viewport.is_inside_tree(), "%s test viewport should enter the scene tree" % context, failures)
	_expect(hud.is_inside_tree(), "%s HUD instance should enter the scene tree" % context, failures)
	if not viewport.is_inside_tree() or not hud.is_inside_tree():
		viewport.queue_free()
		await process_frame
		return

	var layout_root := _require_control(
		hud,
		"LayoutRoot",
		(
			"%s HUD should provide LayoutRoot/BottomPanel/ContentMargin/Regions/"
			+ "{LeftRegion,CenterRegion,RightRegion}"
		) % context,
		failures
	)
	if layout_root == null:
		viewport.queue_free()
		await process_frame
		return

	var bottom_panel := _require_control(
		layout_root,
		"BottomPanel",
		"%s LayoutRoot should contain BottomPanel" % context,
		failures
	)
	var regions := _require_control(
		layout_root,
		"BottomPanel/ContentMargin/Regions",
		"%s HUD should provide BottomPanel/ContentMargin/Regions" % context,
		failures
	)
	if bottom_panel == null or regions == null:
		viewport.queue_free()
		await process_frame
		return

	var left_region := _require_control(
		regions,
		"LeftRegion",
		"%s Regions should contain LeftRegion" % context,
		failures
	)
	var center_region := _require_control(
		regions,
		"CenterRegion",
		"%s Regions should contain CenterRegion" % context,
		failures
	)
	var right_region := _require_control(
		regions,
		"RightRegion",
		"%s Regions should contain RightRegion" % context,
		failures
	)
	if left_region == null or center_region == null or right_region == null:
		viewport.queue_free()
		await process_frame
		return

	var viewport_rect := Rect2(Vector2.ZERO, Vector2(viewport_size))
	var bottom_rect := bottom_panel.get_global_rect()
	var left_rect := left_region.get_global_rect()
	var center_rect := center_region.get_global_rect()
	var right_rect := right_region.get_global_rect()

	_expect(
		viewport_rect.encloses(bottom_rect),
		"%s BottomPanel should remain inside the viewport; got %s" % [context, bottom_rect],
		failures
	)
	_expect(
		not left_rect.intersects(center_rect),
		"%s LeftRegion and CenterRegion should not overlap" % context,
		failures
	)
	_expect(
		not center_rect.intersects(right_rect),
		"%s CenterRegion and RightRegion should not overlap" % context,
		failures
	)
	_expect(
		not left_rect.intersects(right_rect),
		"%s LeftRegion and RightRegion should not overlap" % context,
		failures
	)
	_expect(
		viewport_rect.encloses(right_rect),
		"%s RightRegion should remain inside the viewport; got %s" % [context, right_rect],
		failures
	)

	var status_bars := _require_control(
		left_region,
		"StatusBars",
		"%s LeftRegion should contain StatusBars" % context,
		failures
	)
	var hp_bar: Control = null
	var mp_bar: Control = null
	if status_bars != null:
		var hp_row := _require_control(
			status_bars,
			"HpRow",
			"%s StatusBars should contain HpRow" % context,
			failures
		)
		var mp_row := _require_control(
			status_bars,
			"MpRow",
			"%s StatusBars should contain MpRow" % context,
			failures
		)
		if hp_row != null:
			hp_bar = _require_control(
				hp_row,
				"HpBar",
				"%s HpRow should contain HpBar" % context,
				failures
			)
		if mp_row != null:
			mp_bar = _require_control(
				mp_row,
				"MpBar",
				"%s MpRow should contain MpBar" % context,
				failures
			)
	if hp_bar != null:
		_expect(
			left_rect.encloses(hp_bar.get_global_rect()),
			"%s LeftRegion should enclose HpBar" % context,
			failures
		)
	if mp_bar != null:
		_expect(
			left_rect.encloses(mp_bar.get_global_rect()),
			"%s LeftRegion should enclose MpBar" % context,
			failures
		)

	var quick_slots := _require_control(
		center_region,
		"QuickSlots",
		"%s CenterRegion should contain QuickSlots" % context,
		failures
	)
	if quick_slots != null:
		_expect(
			quick_slots.get_child_count() == 6,
			"%s QuickSlots should retain 6 slots; got %d" % [
				context,
				quick_slots.get_child_count(),
			],
			failures
		)
		_expect(
			center_rect.encloses(quick_slots.get_global_rect()),
			"%s CenterRegion should enclose QuickSlots" % context,
			failures
		)

	var status_label := _require_control(
		right_region,
		"StatusLabel",
		"%s RightRegion should contain StatusLabel" % context,
		failures
	)
	var menu_buttons := _require_control(
		right_region,
		"MenuButtons",
		"%s RightRegion should contain MenuButtons" % context,
		failures
	)
	if status_label != null and menu_buttons != null:
		_expect(
			not status_label.get_global_rect().intersects(menu_buttons.get_global_rect()),
			"%s StatusLabel should not overlap MenuButtons" % context,
			failures
		)
	if menu_buttons != null:
		_expect(
			right_rect.encloses(menu_buttons.get_global_rect()),
			"%s RightRegion should enclose MenuButtons" % context,
			failures
		)

	viewport.queue_free()
	await process_frame


func _require_control(
	parent: Node,
	path: NodePath,
	message: String,
	failures: Array[String]
) -> Control:
	var node := parent.get_node_or_null(path)
	_expect(node is Control, message, failures)
	return node as Control


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
