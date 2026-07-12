extends Area2D
# Attacker-driven melee hitbox. While a swing is active it polls overlapping
# hurtboxes and applies damage once each, so a hit lands every swing regardless
# of area enter/exit timing (which is unreliable when bodies already overlap).

@export var attack: int = 1
@export var enabled: bool = true

var owner_node: Node = null
var _hit_this_swing: Array = []


func _ready() -> void:
	# Always monitoring so get_overlapping_areas() stays current; `enabled` gates a swing.
	monitoring = true
	monitorable = true


func setup(new_owner: Node, new_attack: int) -> void:
	owner_node = new_owner
	attack = maxi(1, new_attack)
	enabled = true


func begin_swing() -> void:
	_hit_this_swing.clear()
	enabled = true


func end_swing() -> void:
	enabled = false
	_hit_this_swing.clear()


func poll_hits() -> void:
	if not enabled:
		return
	for area in get_overlapping_areas():
		if area in _hit_this_swing:
			continue
		if area.has_method("receive_hit"):
			var dealt: int = area.receive_hit(self)
			if dealt > 0:
				_hit_this_swing.append(area)
