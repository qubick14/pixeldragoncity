extends Control

@onready var fill: ColorRect = $Fill

var _max_width: float = 48.0
var current_hp: int = 0
var max_hp: int = 1


func _ready() -> void:
	_max_width = fill.size.x


func bind(health_component: Node) -> void:
	if health_component == null:
		return

	health_component.health_changed.connect(set_health)
	set_health(health_component.current_hp, health_component.max_hp)


func set_health(current_hp: int, max_hp: int) -> void:
	self.current_hp = current_hp
	self.max_hp = maxi(1, max_hp)

	if fill == null:
		return

	var ratio := 0.0
	if self.max_hp > 0:
		ratio = clampf(float(self.current_hp) / float(self.max_hp), 0.0, 1.0)

	fill.size.x = _max_width * ratio
