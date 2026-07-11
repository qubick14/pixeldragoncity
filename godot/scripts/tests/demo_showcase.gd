extends SceneTree
# Dev showcase: renders the live game, then the inventory and equipment panels
# after equipping, so the pixel art + pickup/equip loop can be eyeballed.
# Run non-headless (needs a real renderer).
const MainScene := preload("res://scenes/main.tscn")


func _initialize() -> void:
	root.size = Vector2i(1600, 900)
	var main := MainScene.instantiate()
	root.add_child(main)
	for _i in range(12):
		await process_frame

	await _shot("world")

	# Trigger a downward attack swing and capture it mid-animation.
	var player := main.get_node_or_null("Player")
	if player != null:
		player.facing_direction = Vector2.DOWN
		player.start_attack()
		for _i in range(4):
			await process_frame
		var tex := root.get_texture()
		if tex != null:
			tex.get_image().save_png("/tmp/pixeldragoncity_demo_attack.png")
			print("demo_showcase: saved attack")

	var ui := main.get_node_or_null("UIRoot")
	if ui != null and ui.has_method("show_inventory"):
		ui.show_inventory()
		await _shot("inventory")

	# Equip the starting sword, then show the equipment panel + updated stats.
	main._use_or_equip("wooden_sword")
	if ui != null and ui.has_method("show_equipment"):
		ui.show_equipment()
		await _shot("equipment")

	main.queue_free()
	await process_frame
	print("demo_showcase: PASS")
	quit(0)


func _shot(tag: String) -> void:
	for _i in range(6):
		await process_frame
	var tex := root.get_texture()
	if tex == null:
		push_error("demo_showcase: no renderer")
		return
	tex.get_image().save_png("/tmp/pixeldragoncity_demo_%s.png" % tag)
	print("demo_showcase: saved %s" % tag)
