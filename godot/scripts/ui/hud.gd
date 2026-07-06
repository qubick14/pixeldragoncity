extends CanvasLayer

var _level: int = 1
var _experience_current: int = 0
var _experience_max: int = 100
var _gold: int = 0

var hp_value: Label
var mp_value: Label
var hp_bar: ColorRect
var mp_bar: ColorRect
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
	var ratio := clampf(float(current) / float(maximum), 0.0, 1.0) if maximum > 0 else 0.0
	hp_bar.size.x = 138.0 * ratio


func set_mana(current: int, maximum: int) -> void:
	_ensure_nodes()
	if mp_value == null or mp_bar == null:
		return
	mp_value.text = "%d/%d" % [current, maximum]
	var ratio := clampf(float(current) / float(maximum), 0.0, 1.0) if maximum > 0 else 0.0
	mp_bar.size.x = 98.0 * ratio


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

	var slot := quick_slots.get_child(index)
	slot.set_meta("slot_data", slot_data.duplicate(true))
	if slot is ColorRect:
		slot.color = Color(0.2, 0.16, 0.1, 1.0) if not slot_data.is_empty() else Color(0.13, 0.1, 0.08, 1.0)


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
		hp_value = get_node_or_null("BottomPanel/LeftFrame/HpValue") as Label
	if mp_value == null:
		mp_value = get_node_or_null("BottomPanel/LeftFrame/MpValue") as Label
	if hp_bar == null:
		hp_bar = get_node_or_null("BottomPanel/LeftFrame/HpBar") as ColorRect
	if mp_bar == null:
		mp_bar = get_node_or_null("BottomPanel/LeftFrame/MpBar") as ColorRect
	if status_label == null:
		status_label = get_node_or_null("BottomPanel/StatusLabel") as Label
	if quick_slots == null:
		quick_slots = get_node_or_null("BottomPanel/QuickSlots") as HBoxContainer
