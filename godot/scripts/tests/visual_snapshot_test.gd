extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const SNAPSHOT_PATH := "/tmp/pixeldragoncity_visual_snapshot.png"
const SNAPSHOT_SIZE := Vector2i(1600, 900)


func _initialize() -> void:
	var failures: Array[String] = []
	root.size = SNAPSHOT_SIZE

	var main := MainScene.instantiate()
	root.add_child(main)

	for _i in range(8):
		await process_frame

	var viewport_texture := root.get_texture()
	if viewport_texture == null:
		failures.append("visual snapshot requires a non-dummy renderer; headless mode cannot capture viewport texture")
	else:
		var image := viewport_texture.get_image()
		if image == null:
			failures.append("visual snapshot requires a non-dummy renderer; headless mode returned no image")
		elif image.is_empty():
			failures.append("visual snapshot image should not be empty")
		else:
			var save_error := image.save_png(SNAPSHOT_PATH)
			if save_error != OK:
				failures.append("failed to save visual snapshot: %s" % error_string(save_error))

	main.queue_free()
	await process_frame

	if failures.is_empty():
		print("visual_snapshot_test: PASS %s" % SNAPSHOT_PATH)
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)
