extends RefCounted
class_name UiTheme
# Shared Stardew-ish wooden panel styling for the game's UI panels.

const WOOD := Color(0.33, 0.23, 0.14, 0.98)
const WOOD_DARK := Color(0.14, 0.09, 0.05, 1.0)
const WOOD_LIGHT := Color(0.46, 0.33, 0.2, 1.0)
const GOLD := Color(1.0, 0.9, 0.6, 1.0)
const PARCHMENT := Color(0.86, 0.78, 0.6, 1.0)


static func wood_panel(bg: Color = WOOD) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = WOOD_DARK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(10)
	return sb


static func inset_slot(filled: bool) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.2, 0.14, 0.09, 0.96) if filled else Color(0.12, 0.085, 0.055, 0.9)
	sb.border_color = WOOD_LIGHT
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(2)
	return sb


static func add_panel_bg(host: Control) -> void:
	if host.has_node("PanelBackground"):
		return
	var bg := Panel.new()
	bg.name = "PanelBackground"
	bg.add_theme_stylebox_override("panel", wood_panel())
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = -16.0
	bg.offset_top = -16.0
	bg.offset_right = 16.0
	bg.offset_bottom = 16.0
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	host.add_child(bg)
	host.move_child(bg, 0)


static func style_title(label: Label, text: String = "") -> void:
	if label == null:
		return
	if not text.is_empty():
		label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", GOLD)


static func style_frame(host: Control, bg: Color = Color(0.1, 0.08, 0.06, 0.95)) -> void:
	# For portrait / preview frames: a darker inset with a gold-ish border.
	if host is PanelContainer or host is Panel:
		var sb := wood_panel(bg)
		sb.border_color = WOOD_LIGHT
		host.add_theme_stylebox_override("panel", sb)
