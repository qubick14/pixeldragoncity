extends Control

signal dialogue_closed
signal shop_requested(shop_id: String)

var _lines: Array = []
var _line_index: int = 0
var _shop_id: String = ""
var _finished: bool = false


func _ready() -> void:
	_ensure_signals()
	$QuestButton.visible = false
	visible = false


func start_dialogue(npc_data: Dictionary) -> void:
	_ensure_signals()
	visible = true
	_finished = false
	_line_index = 0
	_lines = npc_data.get("dialogue", []) as Array
	_shop_id = String(npc_data.get("shop_id", ""))
	$NameLabel.text = String(npc_data.get("name", ""))
	$ShopButton.visible = not _shop_id.is_empty()
	$QuestButton.visible = false
	_update_line()


func advance() -> void:
	if _finished:
		return
	if _line_index < _lines.size() - 1:
		_line_index += 1
		_update_line()
		return
	_finished = true
	$NextButton.text = "Close"


func is_finished() -> bool:
	return _finished


func get_shop_id() -> String:
	return _shop_id


func _update_line() -> void:
	if _lines.is_empty():
		$DialogueText.text = ""
		_finished = true
	else:
		$DialogueText.text = String(_lines[_line_index])
	$NextButton.text = "Next"


func _close_dialogue() -> void:
	visible = false
	dialogue_closed.emit()


func _request_shop() -> void:
	if not _shop_id.is_empty():
		shop_requested.emit(_shop_id)


func _ensure_signals() -> void:
	if not $NextButton.pressed.is_connected(advance):
		$NextButton.pressed.connect(advance)
	if not $CloseButton.pressed.is_connected(_close_dialogue):
		$CloseButton.pressed.connect(_close_dialogue)
	if not $ShopButton.pressed.is_connected(_request_shop):
		$ShopButton.pressed.connect(_request_shop)
