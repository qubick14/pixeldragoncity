extends Area2D

@export var attack: int = 1
@export var enabled: bool = true

var owner_node: Node = null


func setup(new_owner: Node, new_attack: int) -> void:
	owner_node = new_owner
	attack = maxi(1, new_attack)
	enabled = true
