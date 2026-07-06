extends Node

var _game_data: Node = null


func setup(game_data_ref: Node) -> void:
	_game_data = game_data_ref


func roll(monster_id: String, rng: RandomNumberGenerator = null) -> Array:
	if _game_data == null or not _game_data.has_monster(monster_id):
		return []

	var active_rng: RandomNumberGenerator = rng if rng != null else RandomNumberGenerator.new()
	if rng == null:
		active_rng.randomize()

	var monster: Dictionary = _game_data.get_monster(monster_id)
	var loot: Array = []
	var gold: int = int(monster.get("gold", 0))
	if gold > 0:
		loot.append({"kind": "gold", "amount": gold})

	for drop in monster.get("drops", []):
		if not drop is Dictionary:
			continue
		var rolled_drop: Dictionary = roll_drop_row(drop, active_rng)
		if not rolled_drop.is_empty():
			loot.append(rolled_drop)

	return loot


func roll_drop_row(drop_row: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var item_id: String = String(drop_row.get("item_id", ""))
	if item_id.is_empty() or _game_data == null or not _game_data.has_item(item_id):
		return {}

	var chance: float = clampf(float(drop_row.get("chance", 0.0)), 0.0, 1.0)
	if rng.randf() > chance:
		return {}

	var min_quantity: int = maxi(1, int(drop_row.get("min", 1)))
	var max_quantity: int = maxi(min_quantity, int(drop_row.get("max", min_quantity)))
	return {
		"kind": "item",
		"item_id": item_id,
		"quantity": rng.randi_range(min_quantity, max_quantity),
	}
