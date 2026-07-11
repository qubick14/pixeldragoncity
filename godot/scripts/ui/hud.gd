extends CanvasLayer

# Quick slots (number keys 1-6) hold consumables; skill slots (F/J/K/L) hold skills.
signal quick_slot_clicked(index: int, double_click: bool)

const SkillIconsSheet := preload("res://assets/ui/skill_icons_sheet.png")
const ItemIconsSheet := preload("res://assets/items/item_icons_sheet.png")
const SKILL_KEY_LABELS := ["J", "K", "L", "U"]

var _level: int = 1
var _experience_current: int = 0
var _experience_max: int = 100
var _gold: int = 0

var hp_value: Label
var mp_value: Label
var hp_bar: ProgressBar
var mp_bar: ProgressBar
var status_label: Label
var quick_slots: HBoxContainer
var skill_slots: HBoxContainer
var name_line_label: Label
var target_root: Control
var target_name_label: Label
var target_hp_bar: ProgressBar
var target_mp_bar: ProgressBar
var target_interact_label: Label
var exp_bar: ProgressBar
var exp_label: Label

var character_name: String = "剑士"


func _ready() -> void:
	_ensure_nodes()
	_update_status_label()


func set_health(current: int, maximum: int) -> void:
	_ensure_nodes()
	if hp_value == null or hp_bar == null:
		return
	hp_value.text = "%d/%d" % [current, maximum]
	hp_bar.max_value = max(maximum, 1)
	hp_bar.value = clampi(current, 0, max(maximum, 0))


func set_mana(current: int, maximum: int) -> void:
	_ensure_nodes()
	if mp_value == null or mp_bar == null:
		return
	mp_value.text = "%d/%d" % [current, maximum]
	mp_bar.max_value = max(maximum, 1)
	mp_bar.value = clampi(current, 0, max(maximum, 0))


func set_experience(current: int, maximum: int) -> void:
	_experience_current = current
	_experience_max = maximum
	_update_status_label()
	_ensure_center_layout()
	if exp_bar != null:
		exp_bar.max_value = max(maximum, 1)
		exp_bar.value = clampi(current, 0, max(maximum, 0))
	if exp_label != null:
		var percent := 0
		if maximum > 0:
			percent = int(round(float(current) / float(maximum) * 100.0))
		exp_label.text = "EXP %d%%" % percent


func set_target(display_name: String, level: int, current_hp: int, max_hp: int, current_mp: int, max_mp: int) -> void:
	_ensure_center_layout()
	if target_root == null:
		return
	target_root.visible = true
	var level_text := "Lv.%d " % level if level > 0 else ""
	target_name_label.text = "%s%s" % [level_text, display_name]
	target_hp_bar.max_value = max(max_hp, 1)
	target_hp_bar.value = clampi(current_hp, 0, max(max_hp, 0))
	target_mp_bar.max_value = max(max_mp, 1)
	target_mp_bar.value = clampi(current_mp, 0, max(max_mp, 0))


func clear_target() -> void:
	if target_root != null:
		target_root.visible = false


func set_character(display_name: String) -> void:
	character_name = display_name
	_update_status_label()


func set_gold(amount: int) -> void:
	_gold = amount
	_update_status_label()


func set_level(value: int) -> void:
	_level = value
	_update_status_label()


# --- Consumable quick slots (keys 1-6) ---------------------------------------
func set_item_slot(index: int, item_data: Dictionary) -> void:
	_ensure_nodes()
	if quick_slots == null or index < 0 or index >= quick_slots.get_child_count():
		return

	var slot := quick_slots.get_child(index) as Control
	slot.set_meta("slot_data", item_data.duplicate(true))
	var icon := _ensure_slot_child(slot, "SkillIcon", "TextureRect") as TextureRect
	var key := _ensure_slot_child(slot, "KeyLabel", "Label") as Label
	var quantity := _ensure_slot_child(slot, "QuantityLabel", "Label") as Label
	_style_key_label(key, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)
	_style_key_label(quantity, HORIZONTAL_ALIGNMENT_RIGHT, VERTICAL_ALIGNMENT_BOTTOM)

	key.text = str(index + 1)
	if item_data.is_empty():
		if slot is ColorRect:
			slot.color = Color(0.13, 0.1, 0.08, 0.16)
		icon.visible = false
		quantity.text = ""
		return

	if slot is ColorRect:
		slot.color = Color(0.2, 0.16, 0.1, 0.55)
	_apply_atlas_icon(icon, ItemIconsSheet, int(item_data.get("icon_index", -1)))
	var count := int(item_data.get("quantity", 0))
	quantity.text = str(count) if count > 1 else ""


# --- Skill slots (keys F/J/K/L) ----------------------------------------------
func set_skill_slot(index: int, skill_data: Dictionary) -> void:
	_ensure_skill_slots()
	if skill_slots == null or index < 0 or index >= skill_slots.get_child_count():
		return

	var slot := skill_slots.get_child(index) as Control
	slot.set_meta("slot_data", skill_data.duplicate(true))
	var icon := _ensure_slot_child(slot, "SkillIcon", "TextureRect") as TextureRect
	var key := _ensure_slot_child(slot, "KeyLabel", "Label") as Label
	var cooldown := _ensure_slot_child(slot, "Cooldown", "ColorRect") as ColorRect
	_style_key_label(key, HORIZONTAL_ALIGNMENT_LEFT, VERTICAL_ALIGNMENT_TOP)

	if skill_data.is_empty():
		if slot is ColorRect:
			slot.color = Color(0.13, 0.1, 0.08, 0.16)
		icon.visible = false
		key.text = ""
		cooldown.visible = false
		return

	if slot is ColorRect:
		slot.color = Color(0.2, 0.16, 0.1, 0.55)
	_apply_atlas_icon(icon, SkillIconsSheet, int(skill_data.get("icon_index", -1)))
	key.text = SKILL_KEY_LABELS[index] if index < SKILL_KEY_LABELS.size() else ""
	cooldown.visible = false


func set_skill_cooldown(index: int, ratio: float) -> void:
	_ensure_skill_slots()
	if skill_slots == null or index < 0 or index >= skill_slots.get_child_count():
		return
	var slot := skill_slots.get_child(index) as Control
	var cooldown := slot.get_node_or_null("Cooldown") as ColorRect
	if cooldown == null:
		return
	if ratio <= 0.0:
		cooldown.visible = false
		return
	cooldown.visible = true
	# Fill from the bottom up: full when ratio=1, gone when ratio=0.
	cooldown.anchor_left = 0.0
	cooldown.anchor_right = 1.0
	cooldown.anchor_bottom = 1.0
	cooldown.anchor_top = clampf(1.0 - ratio, 0.0, 1.0)
	cooldown.offset_left = 0.0
	cooldown.offset_top = 0.0
	cooldown.offset_right = 0.0
	cooldown.offset_bottom = 0.0


func _apply_atlas_icon(icon: TextureRect, sheet: Texture2D, icon_index: int) -> void:
	if icon_index < 0:
		icon.visible = false
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(icon_index * 32, 0, 32, 32)
	icon.texture = atlas
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.visible = true


func _style_key_label(label: Label, h_align: int, v_align: int) -> void:
	label.horizontal_alignment = h_align
	label.vertical_alignment = v_align
	label.add_theme_color_override("font_color", Color(1, 0.92, 0.65))
	label.add_theme_font_size_override("font_size", 12)


func _ensure_slot_child(slot: Control, child_name: String, type_name: String) -> Control:
	var existing := slot.get_node_or_null(child_name) as Control
	if existing != null:
		return existing
	var node: Control
	match type_name:
		"TextureRect":
			var rect := TextureRect.new()
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			node = rect
		"Label":
			var label := Label.new()
			label.add_theme_font_size_override("font_size", 12)
			node = label
		_:
			var color_rect := ColorRect.new()
			color_rect.color = Color(0.02, 0.02, 0.03, 0.55)
			color_rect.visible = false
			node = color_rect
	node.name = child_name
	node.set_anchors_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(node)
	return node


func _update_status_label() -> void:
	_ensure_nodes()
	if status_label == null:
		return
	var exp_percent := 0
	if _experience_max > 0:
		exp_percent = int(round(float(_experience_current) / float(_experience_max) * 100.0))
	status_label.text = "Lv.%d  EXP %d%%  Gold %d" % [_level, exp_percent, _gold]
	if name_line_label != null:
		name_line_label.text = "%s  Lv.%d  金币 %d" % [character_name, _level, _gold]


func _ensure_nodes() -> void:
	var base := "LayoutRoot/BottomPanel/ContentMargin/Regions"
	if hp_value == null:
		hp_value = get_node_or_null("%s/LeftRegion/StatusBars/HpRow/HpValue" % base) as Label
	if mp_value == null:
		mp_value = get_node_or_null("%s/LeftRegion/StatusBars/MpRow/MpValue" % base) as Label
	if hp_bar == null:
		hp_bar = get_node_or_null("%s/LeftRegion/StatusBars/HpRow/HpBar" % base) as ProgressBar
	if mp_bar == null:
		mp_bar = get_node_or_null("%s/LeftRegion/StatusBars/MpRow/MpBar" % base) as ProgressBar
	if status_label == null:
		status_label = get_node_or_null("%s/RightRegion/StatusLabel" % base) as Label
	if quick_slots == null:
		quick_slots = get_node_or_null("%s/CenterRegion/QuickSlots" % base) as HBoxContainer
		_connect_quick_slots()
	_ensure_center_fill()
	_ensure_skill_slots()
	_ensure_center_layout()


func _ensure_center_layout() -> void:
	# Center region is split into two columns:
	#   left  = character line / skill bar / item bar / EXP bar (rows 1-4)
	#   right = target info (level+name, HP, MP, interaction slot)
	if name_line_label != null and is_instance_valid(name_line_label):
		return
	var center := get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/CenterRegion") as Control
	if center == null:
		return

	# Left column, row 1: character name + level + gold.
	name_line_label = Label.new()
	name_line_label.name = "CharacterLine"
	name_line_label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	name_line_label.offset_left = 14.0
	name_line_label.offset_top = 6.0
	name_line_label.add_theme_font_size_override("font_size", 16)
	name_line_label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	name_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(name_line_label)

	# Left column, row 3: reposition the consumable quick slots from the scene.
	if quick_slots == null:
		quick_slots = center.get_node_or_null("QuickSlots") as HBoxContainer
		_connect_quick_slots()
	if quick_slots != null:
		quick_slots.set_anchors_preset(Control.PRESET_TOP_LEFT)
		# The scene sets grow=BOTH which recentres the row; anchor it left-to-right instead.
		quick_slots.grow_horizontal = Control.GROW_DIRECTION_END
		quick_slots.grow_vertical = Control.GROW_DIRECTION_END
		quick_slots.offset_left = 14.0
		quick_slots.offset_top = 80.0
		quick_slots.offset_right = 0.0
		quick_slots.offset_bottom = 0.0

	# Left column, row 4: EXP bar with overlaid percentage, pinned to the bottom.
	var exp_holder := Control.new()
	exp_holder.name = "ExpHolder"
	exp_holder.anchor_left = 0.0
	exp_holder.anchor_right = 0.6
	exp_holder.anchor_top = 1.0
	exp_holder.anchor_bottom = 1.0
	exp_holder.offset_left = 14.0
	exp_holder.offset_right = -8.0
	exp_holder.offset_top = -20.0
	exp_holder.offset_bottom = -4.0
	exp_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(exp_holder)
	exp_bar = ProgressBar.new()
	exp_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	exp_bar.show_percentage = false
	exp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_holder.add_child(exp_bar)
	exp_label = Label.new()
	exp_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	exp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	exp_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	exp_label.add_theme_font_size_override("font_size", 12)
	exp_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	exp_holder.add_child(exp_label)

	# Column divider.
	var divider := ColorRect.new()
	divider.name = "ColumnDivider"
	divider.color = Color(0.5, 0.4, 0.25, 0.5)
	divider.anchor_left = 0.61
	divider.anchor_right = 0.61
	divider.anchor_top = 0.0
	divider.anchor_bottom = 1.0
	divider.offset_left = -1.0
	divider.offset_right = 1.0
	divider.offset_top = 8.0
	divider.offset_bottom = -8.0
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(divider)

	# Right column: target info (hidden until a target is set).
	target_root = VBoxContainer.new()
	target_root.name = "TargetInfo"
	target_root.anchor_left = 0.63
	target_root.anchor_right = 1.0
	target_root.anchor_top = 0.0
	target_root.anchor_bottom = 1.0
	target_root.offset_left = 8.0
	target_root.offset_right = -12.0
	target_root.offset_top = 6.0
	target_root.offset_bottom = -6.0
	target_root.add_theme_constant_override("separation", 3)
	target_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	target_root.visible = false
	center.add_child(target_root)

	target_name_label = Label.new()
	target_name_label.add_theme_font_size_override("font_size", 14)
	target_name_label.add_theme_color_override("font_color", Color(1, 0.8, 0.7))
	target_root.add_child(target_name_label)
	target_hp_bar = _make_target_bar(target_root, "HP", Color(0.8, 0.3, 0.3))
	target_mp_bar = _make_target_bar(target_root, "MP", Color(0.35, 0.5, 0.9))
	target_interact_label = Label.new()
	target_interact_label.text = "[E] 对话"
	target_interact_label.add_theme_font_size_override("font_size", 12)
	target_interact_label.add_theme_color_override("font_color", Color(0.7, 0.95, 1))
	target_root.add_child(target_interact_label)


func _make_target_bar(parent: Control, label_text: String, tint: Color) -> ProgressBar:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(26, 0)
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color(0.8, 0.74, 0.55))
	row.add_child(label)
	var bar := ProgressBar.new()
	bar.custom_minimum_size = Vector2(0, 12)
	bar.show_percentage = false
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.modulate = tint
	row.add_child(bar)
	return bar


func _ensure_center_fill() -> void:
	# The center atlas art paints oversized cells; replace it with a flat wood panel
	# so only the compact functional slots read as the quick bar.
	var center := get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/CenterRegion") as Control
	if center == null:
		return
	var atlas_bg := center.get_node_or_null("Background") as Control
	if atlas_bg != null:
		atlas_bg.visible = false
	if center.has_node("CenterFill"):
		return
	var fill := ColorRect.new()
	fill.name = "CenterFill"
	fill.color = Color(0.30, 0.2, 0.12, 1.0)
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(fill)
	center.move_child(fill, 0)


func _connect_quick_slots() -> void:
	if quick_slots == null:
		return
	for i in range(quick_slots.get_child_count()):
		var slot := quick_slots.get_child(i) as Control
		if slot == null or slot.has_meta("click_connected"):
			continue
		slot.set_meta("click_connected", true)
		slot.gui_input.connect(_on_quick_slot_gui_input.bind(i))


func _on_quick_slot_gui_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		quick_slot_clicked.emit(index, event.double_click)


func _ensure_skill_slots() -> void:
	if skill_slots != null and is_instance_valid(skill_slots):
		return
	var center := get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/CenterRegion") as Control
	if center == null:
		return
	skill_slots = HBoxContainer.new()
	skill_slots.name = "SkillSlots"
	skill_slots.add_theme_constant_override("separation", 8)
	# Left column, row 2 (below the name line).
	skill_slots.set_anchors_preset(Control.PRESET_TOP_LEFT)
	skill_slots.offset_left = 14.0
	skill_slots.offset_top = 32.0
	center.add_child(skill_slots)
	for i in range(4):
		var slot := ColorRect.new()
		slot.name = "SkillSlot%d" % (i + 1)
		slot.custom_minimum_size = Vector2(44, 44)
		slot.color = Color(0.13, 0.1, 0.08, 0.16)
		skill_slots.add_child(slot)
