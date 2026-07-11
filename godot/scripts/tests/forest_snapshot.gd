extends SceneTree
# Dev screenshot helper: renders the Black Wolf Forest with a player so the
# wolf/monster pixel art and forest background can be eyeballed. Non-headless.
const Forest := preload("res://scenes/maps/black_wolf_forest.tscn")
const Player := preload("res://scenes/actors/player.tscn")
const OUT := "/tmp/pixeldragoncity_forest.png"


func _initialize() -> void:
	root.size = Vector2i(1600, 900)
	var forest := Forest.instantiate()
	root.add_child(forest)
	var player := Player.instantiate()
	player.position = Vector2(0, 0)
	forest.add_child(player)
	for _i in range(16):
		await process_frame
	var tex := root.get_texture()
	if tex == null:
		push_error("forest_snapshot: no renderer")
		quit(1)
		return
	var img := tex.get_image()
	img.save_png(OUT)
	print("forest_snapshot: PASS %s" % OUT)
	quit(0)
