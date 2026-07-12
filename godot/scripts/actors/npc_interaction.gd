extends Area2D

signal interacted(npc_id: String)

@export var npc_id: String = ""
@export var display_name: String = ""

@onready var name_label: Label = $NameLabel


func _ready() -> void:
	if name_label != null:
		name_label.text = display_name
	_apply_sprite()


func _apply_sprite() -> void:
	var sprite := get_node_or_null("GeneratedSprite") as Sprite2D
	if sprite == null:
		return
	var path := "res://assets/sprites/npc/npc_%s.png" % npc_id
	if ResourceLoader.exists(path):
		sprite.texture = load(path)


func interact() -> void:
	var ui_root := _find_ui_root()
	if ui_root != null and ui_root.has_method("show_dialogue"):
		ui_root.show_dialogue(npc_id)
	interacted.emit(npc_id)


func _find_ui_root() -> Node:
	var current: Node = self
	while current != null:
		if current.has_node("UIRoot"):
			return current.get_node("UIRoot")
		current = current.get_parent()
	return null
