extends Node

signal health_changed(current_hp: int, max_hp: int)
signal damaged(amount: int, source: Variant)
signal healed(amount: int)
signal died(source: Variant)

@export var max_hp: int = 1
@export var defense: int = 0

var current_hp: int = 1
var _dead_signal_emitted: bool = false


func _ready() -> void:
	current_hp = clampi(current_hp, 0, max_hp)


func setup(new_max_hp: int, new_defense: int) -> void:
	max_hp = maxi(1, new_max_hp)
	defense = maxi(0, new_defense)
	current_hp = max_hp
	_dead_signal_emitted = false
	health_changed.emit(current_hp, max_hp)


func apply_damage(raw_attack: int, source: Variant) -> int:
	if is_dead():
		return 0

	var final_damage := maxi(1, raw_attack - defense)
	current_hp = maxi(0, current_hp - final_damage)
	damaged.emit(final_damage, source)
	health_changed.emit(current_hp, max_hp)

	if current_hp == 0 and not _dead_signal_emitted:
		_dead_signal_emitted = true
		died.emit(source)

	return final_damage


func heal(amount: int) -> int:
	if amount <= 0 or is_dead():
		return 0

	var previous_hp := current_hp
	current_hp = mini(max_hp, current_hp + amount)
	var restored := current_hp - previous_hp

	if restored > 0:
		healed.emit(restored)
		health_changed.emit(current_hp, max_hp)

	return restored


func is_dead() -> bool:
	return current_hp <= 0
