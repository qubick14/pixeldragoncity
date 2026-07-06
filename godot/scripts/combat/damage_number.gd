extends Label

@export var lifetime: float = 0.75
@export var float_distance: float = 22.0

var _age: float = 0.0
var _start_position: Vector2 = Vector2.ZERO


func setup(amount: int) -> void:
	text = str(amount)
	_start_position = position
	modulate = Color(1.0, 0.86, 0.36, 1.0)
	call_deferred("_start_lifetime_timer")


func _start_lifetime_timer() -> void:
	if is_inside_tree():
		get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _process(delta: float) -> void:
	_age += delta
	var progress := clampf(_age / lifetime, 0.0, 1.0)
	position = _start_position + Vector2(0, -float_distance * progress)
	modulate.a = 1.0 - progress

	if _age >= lifetime:
		queue_free()
