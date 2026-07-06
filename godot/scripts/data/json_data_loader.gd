extends RefCounted


func load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_error("JSON file does not exist: %s" % path)
		return null

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open JSON file: %s" % path)
		return null

	var content: String = file.get_as_text()
	var parsed: Variant = JSON.parse_string(content)
	if parsed == null:
		push_error("Failed to parse JSON file: %s" % path)
		return null

	return parsed
