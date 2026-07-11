extends Control
# Skills-and-talents screen (key V). Lists the class's skills; talents are a placeholder.

const SkillIconsSheet := preload("res://assets/ui/skill_icons_sheet.png")

var _skill_list: VBoxContainer = null


func _ready() -> void:
	_build()


func set_skills(skills: Array) -> void:
	_build()
	for child in _skill_list.get_children():
		child.queue_free()
	for skill in skills:
		if not skill is Dictionary:
			continue
		_skill_list.add_child(_make_skill_row(skill))


func _make_skill_row(skill: Dictionary) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var icon_index := int(skill.get("icon_index", -1))
	if icon_index >= 0:
		var atlas := AtlasTexture.new()
		atlas.atlas = SkillIconsSheet
		atlas.region = Rect2(icon_index * 32, 0, 32, 32)
		icon.texture = atlas
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(icon)

	var name_label := Label.new()
	name_label.text = String(skill.get("name", ""))
	name_label.custom_minimum_size = Vector2(96, 0)
	row.add_child(name_label)

	var info := Label.new()
	info.text = "CD %.2fs · MP %d · %.1f倍" % [
		float(skill.get("cooldown", 0.0)),
		int(skill.get("mp_cost", 0)),
		float(skill.get("multiplier", 1.0)),
	]
	info.add_theme_color_override("font_color", Color(0.8, 0.74, 0.55))
	row.add_child(info)
	return row


func _build() -> void:
	if _skill_list != null:
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
	content.add_theme_constant_override("separation", 10)
	add_child(content)

	content.add_child(_header("技能与天赋", 22))
	content.add_child(_header("技能", 16))
	_skill_list = VBoxContainer.new()
	_skill_list.name = "SkillList"
	_skill_list.add_theme_constant_override("separation", 8)
	content.add_child(_skill_list)

	content.add_child(_header("天赋", 16))
	var talent := Label.new()
	talent.text = "天赋系统即将推出"
	talent.add_theme_color_override("font_color", Color(0.6, 0.55, 0.42))
	content.add_child(talent)


func _header(text: String, size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	return label


func _ensure_panel_background() -> void:
	if has_node("PanelBackground"):
		return
	var background := ColorRect.new()
	background.name = "PanelBackground"
	background.color = Color(0.075, 0.055, 0.04, 0.95)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
