extends Area2D

@export var health_component_path: NodePath


func receive_hit(hitbox: Area2D) -> int:
	if hitbox == null:
		return 0
	if not _is_valid_hitbox(hitbox):
		return 0

	var health_component := get_health_component()
	if health_component == null:
		return 0

	return health_component.apply_damage(hitbox.attack, hitbox.owner_node)


func get_health_component() -> Node:
	if health_component_path != NodePath("") and has_node(health_component_path):
		return get_node(health_component_path)

	return get_parent().get_node_or_null("HealthComponent")


func _is_valid_hitbox(hitbox: Area2D) -> bool:
	if not "enabled" in hitbox or not "attack" in hitbox or not "owner_node" in hitbox:
		return false
	if not hitbox.enabled:
		return false
	if hitbox.owner_node != null and hitbox.owner_node == get_parent():
		return false

	return true
