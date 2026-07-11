extends CanvasLayer

const SkillIconsSheet := preload("res://assets/ui/skill_icons_sheet.png")

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


func set_quick_slot(index: int, slot_data: Dictionary) -> void:
	_ensure_nodes()
	if quick_slots == null:
		return
	if index < 0 or index >= quick_slots.get_child_count():
		return

	var slot := quick_slots.get_child(index) as Control
	slot.set_meta("slot_data", slot_data.duplicate(true))
	var icon := _ensure_slot_child(slot, "SkillIcon", "TextureRect") as TextureRect
	var key := _ensure_slot_child(slot, "KeyLabel", "Label") as Label
	var cooldown := _ensure_slot_child(slot, "Cooldown", "ColorRect") as ColorRect

	if slot_data.is_empty():
		if slot is ColorRect:
			slot.color = Color(0.13, 0.1, 0.08, 1.0)
		icon.visible = false
		key.text = ""
		cooldown.visible = false
		return

	if slot is ColorRect:
		slot.color = Color(0.2, 0.16, 0.1, 1.0)
	var icon_index := int(slot_data.get("icon_index", -1))
	if icon_index >= 0:
		var atlas := AtlasTexture.new()
		atlas.atlas = SkillIconsSheet
		atlas.region = Rect2(icon_index * 32, 0, 32, 32)
		icon.texture = atlas
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.visible = true
	else:
		icon.visible = false
	key.text = str(index + 1)
	cooldown.visible = false


func set_skill_cooldown(index: int, ratio: float) -> void:
	_ensure_nodes()
	if quick_slots == null or index < 0 or index >= quick_slots.get_child_count():
		return
	var slot := quick_slots.get_child(index) as Control
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
	if hp_value == null:
		hp_value = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/HpRow/HpValue") as Label
	if mp_value == null:
		mp_value = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/MpRow/MpValue") as Label
	if hp_bar == null:
		hp_bar = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/HpRow/HpBar") as ProgressBar
	if mp_bar == null:
		mp_bar = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/LeftRegion/StatusBars/MpRow/MpBar") as ProgressBar
	if status_label == null:
		status_label = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/RightRegion/StatusLabel") as Label
	if quick_slots == null:
		quick_slots = get_node_or_null("LayoutRoot/BottomPanel/ContentMargin/Regions/CenterRegion/QuickSlots") as HBoxContainer
