extends Node

var _quest_states := {
	"first_hunt": "not_started",
}
var _wild_wolf_defeated: int = 0


func get_quest_state(quest_id: String) -> String:
	return String(_quest_states.get(quest_id, "not_started"))


func start_first_hunt() -> void:
	if get_quest_state("first_hunt") == "not_started":
		_quest_states["first_hunt"] = "active"


func complete_first_hunt() -> void:
	if get_quest_state("first_hunt") == "ready_to_turn_in":
		_quest_states["first_hunt"] = "completed"


func record_wild_wolf_defeated() -> void:
	if get_quest_state("first_hunt") == "not_started":
		start_first_hunt()
	_wild_wolf_defeated += 1


func get_wild_wolf_defeated() -> int:
	return _wild_wolf_defeated


func record_black_wolf_leader_defeated() -> void:
	if get_quest_state("first_hunt") == "active":
		_quest_states["first_hunt"] = "ready_to_turn_in"
