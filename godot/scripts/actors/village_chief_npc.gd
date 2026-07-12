extends Node2D

signal interacted(npc_id: String)

@export var npc_id: String = "village_chief"


func _ready() -> void:
	var sprite := get_node_or_null("GeneratedSprite") as Sprite2D
	var path := "res://assets/sprites/npc/npc_%s.png" % npc_id
	if sprite != null and ResourceLoader.exists(path):
		sprite.texture = load(path)


func interact() -> void:
	var ui_root := _find_ui_root()
	if ui_root != null and ui_root.has_method("show_dialogue"):
		ui_root.show_dialogue(npc_id)
	interacted.emit(npc_id)

	var quest_manager := _find_quest_manager()
	if quest_manager == null:
		return

	var state: String = quest_manager.get_quest_state("first_hunt")
	if state == "not_started":
		quest_manager.start_first_hunt()
	elif state == "ready_to_turn_in":
		quest_manager.complete_first_hunt()


func _find_ui_root() -> Node:
	var current: Node = self
	while current != null:
		if current.has_node("UIRoot"):
			return current.get_node("UIRoot")
		current = current.get_parent()
	return null


func _find_quest_manager() -> Node:
	var current := get_parent()
	while current != null:
		if current.has_node("QuestManager"):
			return current.get_node("QuestManager")
		current = current.get_parent()
	return null
