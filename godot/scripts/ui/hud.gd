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
	_ensure_skill_slots()


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
	skill_slots.add_theme_constant_override("separation", 4)
	# Anchor centered, sit just above the consumable quick slots.
	skill_slots.set_anchors_preset(Control.PRESET_CENTER)
	skill_slots.offset_left = -92.0
	skill_slots.offset_right = 92.0
	skill_slots.offset_top = -78.0
	skill_slots.offset_bottom = -38.0
	center.add_child(skill_slots)
	for i in range(4):
		var slot := ColorRect.new()
		slot.name = "SkillSlot%d" % (i + 1)
		slot.custom_minimum_size = Vector2(40, 40)
		slot.color = Color(0.13, 0.1, 0.08, 0.16)
		skill_slots.add_child(slot)
