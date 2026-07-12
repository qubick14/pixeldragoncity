extends Node2D
# Short-lived expanding ring VFX for AoE skills. Self-frees when done.

var _t: float = 0.0
var _dur: float = 0.35
var _max_r: float = 140.0


func setup(radius: float) -> void:
	_max_r = radius


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t >= _dur:
		queue_free()


func _draw() -> void:
	var f: float = clampf(_t / _dur, 0.0, 1.0)
	var r: float = _max_r * f
	var a: float = (1.0 - f) * 0.85
	draw_arc(Vector2.ZERO, r, 0.0, TAU, 56, Color(0.6, 0.85, 1.0, a), 4.0)
	draw_arc(Vector2.ZERO, r * 0.72, 0.0, TAU, 56, Color(0.82, 0.95, 1.0, a * 0.7), 2.0)
