extends Control
# Quest log screen (key N). Shows quest title/description/objective and state.

const STATE_LABELS := {
	"not_started": "未接取",
	"active": "进行中",
	"ready_to_turn_in": "可提交",
	"completed": "已完成",
}

var _quest_list: VBoxContainer = null


func _ready() -> void:
	_build()


func set_quests(quests: Array) -> void:
	_build()
	for child in _quest_list.get_children():
		child.queue_free()
	if quests.is_empty():
		var empty := Label.new()
		empty.text = "暂无任务"
		empty.add_theme_color_override("font_color", Color(0.6, 0.55, 0.42))
		_quest_list.add_child(empty)
		return
	for quest in quests:
		if quest is Dictionary:
			_quest_list.add_child(_make_quest_entry(quest))


func _make_quest_entry(quest: Dictionary) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	var title := Label.new()
	title.text = String(quest.get("title", ""))
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	header.add_child(title)
	var state := Label.new()
	var state_key := String(quest.get("state", "not_started"))
	state.text = "[%s]" % STATE_LABELS.get(state_key, state_key)
	state.add_theme_color_override("font_color", _state_color(state_key))
	header.add_child(state)
	box.add_child(header)

	var desc := Label.new()
	desc.text = String(quest.get("description", ""))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(400, 0)
	desc.add_theme_color_override("font_color", Color(0.82, 0.76, 0.6))
	box.add_child(desc)

	var objective := Label.new()
	objective.text = "目标：%s" % String(quest.get("objective", ""))
	objective.add_theme_color_override("font_color", Color(0.75, 0.7, 0.5))
	box.add_child(objective)
	return box


func _state_color(state_key: String) -> Color:
	match state_key:
		"completed":
			return Color(0.5, 0.8, 0.5)
		"ready_to_turn_in":
			return Color(1, 0.85, 0.4)
		"active":
			return Color(0.7, 0.85, 1)
		_:
			return Color(0.65, 0.6, 0.5)


func _build() -> void:
	if _quest_list != null:
		return
	custom_minimum_size = Vector2(460, 420)
	_ensure_panel_background()

	var content := VBoxContainer.new()
	content.name = "Content"
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 20
	content.offset_top = 18
	content.offset_right = -20
	content.offset_bottom = -18
	content.add_theme_constant_override("separation", 12)
	add_child(content)

	var title := Label.new()
	title.text = "任务"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	content.add_child(title)

	_quest_list = VBoxContainer.new()
	_quest_list.name = "QuestList"
	_quest_list.add_theme_constant_override("separation", 14)
	content.add_child(_quest_list)


func _ensure_panel_background() -> void:
	UiTheme.add_panel_bg(self)
