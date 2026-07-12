extends Area2D
# A flying skill projectile (e.g. fireball). Acts as its own attacker hitbox:
# each physics frame it advances, then polls overlapping hurtboxes and applies
# damage (owner-excluded), popping on the first target hit or when it expires.

@export var attack: int = 10
@export var enabled: bool = true
var owner_node: Node = null

var _dir: Vector2 = Vector2.RIGHT
var _speed: float = 300.0
var _life: float = 1.4


func _ready() -> void:
	monitoring = true
	monitorable = true


func setup(new_owner: Node, damage: int, direction: Vector2, speed: float = 300.0, lifetime: float = 1.4) -> void:
	owner_node = new_owner
	attack = maxi(1, damage)
	_dir = direction.normalized() if direction.length() > 0.01 else Vector2.RIGHT
	_speed = speed
	_life = lifetime
	rotation = _dir.angle()


func _physics_process(delta: float) -> void:
	global_position += _dir * _speed * delta
	_life -= delta
	if _life <= 0.0:
		queue_free()
		return
	for area in get_overlapping_areas():
		if area.has_method("receive_hit"):
			var dealt: int = area.receive_hit(self)
			if dealt > 0:
				queue_free()
				return
