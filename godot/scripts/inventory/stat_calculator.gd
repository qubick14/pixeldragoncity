extends RefCounted


static func calculate(base_stats: Dictionary, equipment_model: Node, game_data_ref: Node) -> Dictionary:
	var result: Dictionary = base_stats.duplicate(true)
	for stat_name: String in ["attack", "magic_attack", "defense", "max_hp", "max_mp", "speed", "crit_rate"]:
		if not result.has(stat_name):
			result[stat_name] = 0
	for slot: String in ["weapon", "armor"]:
		var item_id: String = equipment_model.get_equipped_item_id(slot)
		if item_id.is_empty():
			continue

		var item: Dictionary = game_data_ref.get_item(item_id)
		var stats: Dictionary = item.get("stats", {}) as Dictionary
		for stat_name: String in stats:
			result[stat_name] = result.get(stat_name, 0) + stats[stat_name]

	return result
