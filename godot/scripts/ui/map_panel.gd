extends Control
# World map screen (key M). Draws maps as nodes with connection lines; current is highlighted.

const NODE_RADIUS := 16.0

var _nodes: Array = []      # [{ "id": String, "name": String, "pos": Vector2, "current": bool }]
var _edges: Array = []      # [[Vector2, Vector2], ...]
var _labels_root: Control = null


func _ready() -> void:
	_build()


func set_map(maps: Array, current_id: String) -> void:
	_build()
	_nodes.clear()
	_edges.clear()
	for child in _labels_root.get_children():
		child.queue_free()

	# Lay the maps out left-to-right across the drawing area.
	var count := maps.size()
	var area_left := 60.0
	var area_right := custom_minimum_size.x - 60.0
	var y := custom_minimum_size.y * 0.5 + 10.0
	var index_by_id := {}
	for i in range(count):
		var map: Dictionary = maps[i] if maps[i] is Dictionary else {}
		var t := 0.5 if count <= 1 else float(i) / float(count - 1)
		var pos := Vector2(lerpf(area_left, area_right, t), y + (30.0 if i % 2 == 1 else -30.0))
		var id := String(map.get("id", ""))
		index_by_id[id] = _nodes.size()
		_nodes.append({
			"id": id,
			"name": String(map.get("name", id)),
			"pos": pos,
			"current": id == current_id,
		})

	# Build unique connection edges.
	var seen := {}
	for map in maps:
		if not map is Dictionary:
			continue
		var from_id := String(map.get("id", ""))
		for to_id in map.get("connections", []):
			var key := from_id + "|" + String(to_id) if from_id < String(to_id) else String(to_id) + "|" + from_id
			if seen.has(key) or not index_by_id.has(from_id) or not index_by_id.has(String(to_id)):
				continue
			seen[key] = true
			_edges.append([_nodes[index_by_id[from_id]].pos, _nodes[index_by_id[String(to_id)]].pos])

	for node in _nodes:
		var label := Label.new()
		label.text = node.name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.custom_minimum_size = Vector2(120, 0)
		label.position = node.pos + Vector2(-60, NODE_RADIUS + 4)
		if node.current:
			label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
		_labels_root.add_child(label)

	queue_redraw()


func _draw() -> void:
	for edge in _edges:
		draw_line(edge[0], edge[1], Color(0.5, 0.42, 0.28), 2.0)
	for node in _nodes:
		var color: Color = Color(0.85, 0.7, 0.3) if node.current else Color(0.4, 0.34, 0.24)
		draw_circle(node.pos, NODE_RADIUS, color)
		if node.current:
			draw_arc(node.pos, NODE_RADIUS + 4.0, 0.0, TAU, 32, Color(1, 0.9, 0.5), 2.0)


func _build() -> void:
	if _labels_root != null:
		return
	custom_minimum_size = Vector2(520, 360)
	_ensure_panel_background()

	var title := Label.new()
	title.name = "Title"
	title.text = "地图"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.6))
	title.position = Vector2(20, 16)
	add_child(title)

	_labels_root = Control.new()
	_labels_root.name = "Labels"
	_labels_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_labels_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_labels_root)


func _ensure_panel_background() -> void:
	if has_node("PanelBackground"):
		return
	var background := ColorRect.new()
	background.name = "PanelBackground"
	background.color = Color(0.075, 0.055, 0.04, 0.95)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
