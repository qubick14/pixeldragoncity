extends Node2D

const GameDataScript := preload("res://scripts/data/game_data.gd")
const InventoryModelScript := preload("res://scripts/inventory/inventory_model.gd")
const EquipmentModelScript := preload("res://scripts/inventory/equipment_model.gd")

var _game_data: Node = null
var _inventory: Node = null
var _equipment: Node = null
var _base_attack: int = 12
var _base_defense: int = 2
var _base_max_hp: int = 100
var _skill_bar: Array = []


func _ready() -> void:
	print("Pixel Dragon City v0.2 combat prototype loaded")
	_setup_game_session()
	_setup_v05_map_flow()
	_connect_player_interaction()
	_connect_combat_prototype()
	_setup_skills()


func _process(_delta: float) -> void:
	var player := get_node_or_null("Player")
	var hud := get_node_or_null("HUD")
	if player == null or hud == null or _skill_bar.is_empty():
		return
	if not player.has_method("get_skill_cooldown_remaining"):
		return
	for i in range(_skill_bar.size()):
		var skill: Dictionary = _skill_bar[i]
		var total := float(skill.get("cooldown", 1.0))
		var remaining: float = player.get_skill_cooldown_remaining(String(skill.get("id", "")))
		hud.set_skill_cooldown(i, remaining / total if total > 0.0 else 0.0)


func _setup_skills() -> void:
	var player := get_node_or_null("Player")
	var hud := get_node_or_null("HUD")
	if player == null or _game_data == null:
		return
	_skill_bar = _game_data.get_skills_for_class("swordsman")
	if player.has_method("set_skill_bar"):
		player.set_skill_bar(_skill_bar)
	if player.has_signal("mana_changed") and not player.mana_changed.is_connected(_on_player_mana_changed):
		player.mana_changed.connect(_on_player_mana_changed)
	if hud == null:
		return
	for i in range(6):
		hud.set_quick_slot(i, _skill_bar[i] if i < _skill_bar.size() else {})
	hud.set_mana(int(player.get("current_mp")), int(player.get("max_mp")))


func _on_player_mana_changed(current_mp: int, max_mp: int) -> void:
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("set_mana"):
		hud.set_mana(current_mp, max_mp)


func _setup_v05_map_flow() -> void:
	var map_manager := get_node_or_null("MapManager")
	if map_manager == null:
		return

	if map_manager.has_signal("map_loaded") and not map_manager.map_loaded.is_connected(_on_map_loaded):
		map_manager.map_loaded.connect(_on_map_loaded)

	if map_manager.current_map_id.is_empty():
		map_manager.load_map("greenwood_village", "village_spawn")
	else:
		_connect_enemy_deaths(map_manager.get_current_map())


func _connect_player_interaction() -> void:
	var player := get_node_or_null("Player")
	if player == null or not player.has_signal("interact_requested"):
		return
	if not player.interact_requested.is_connected(_on_player_interact_requested):
		player.interact_requested.connect(_on_player_interact_requested)


func _on_player_interact_requested() -> void:
	var map_manager := get_node_or_null("MapManager")
	if map_manager == null:
		return

	var current_map: Node = map_manager.get_current_map()
	if current_map == null or not current_map.has_node("Npcs"):
		return

	var player := get_node_or_null("Player") as Node2D
	if player == null:
		return

	var nearest_npc: Node2D = null
	var nearest_distance := INF
	for npc in current_map.get_node("Npcs").get_children():
		if not npc is Node2D or not npc.has_method("interact"):
			continue
		var distance := player.global_position.distance_to(npc.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_npc = npc

	if nearest_npc != null and nearest_distance <= 260.0:
		nearest_npc.interact()
		_show_npc_dialogue(nearest_npc)


func _show_npc_dialogue(npc: Node) -> void:
	var ui_root := get_node_or_null("UIRoot")
	if ui_root == null or not ui_root.has_method("show_dialogue"):
		return

	var npc_id := String(npc.get("npc_id"))
	if npc_id.is_empty():
		return

	ui_root.show_dialogue(npc_id)


func _on_map_loaded(_map_id: String, map_node: Node) -> void:
	_connect_enemy_deaths(map_node)


func _connect_enemy_deaths(map_node: Node) -> void:
	var quest_manager := get_node_or_null("QuestManager")
	if quest_manager == null or map_node == null or not map_node.has_node("Enemies"):
		return

	for enemy in map_node.get_node("Enemies").get_children():
		if not enemy is Node:
			continue
		var health_component := enemy.get_node_or_null("HealthComponent")
		if health_component == null or not health_component.has_signal("died"):
			continue
		var died_callback := Callable(self, "_on_enemy_died").bind(enemy)
		if not health_component.died.is_connected(died_callback):
			health_component.died.connect(died_callback)


func _on_enemy_died(_source: Variant, enemy: Node) -> void:
	var quest_manager := get_node_or_null("QuestManager")
	if quest_manager == null:
		return

	var monster_id := String(enemy.get("monster_id"))
	if monster_id == "wild_wolf" and quest_manager.has_method("record_wild_wolf_defeated"):
		quest_manager.record_wild_wolf_defeated()
	elif monster_id == "black_wolf_leader" and quest_manager.has_method("record_black_wolf_leader_defeated"):
		quest_manager.record_black_wolf_leader_defeated()


func _connect_combat_prototype() -> void:
	var player := get_node_or_null("Player")
	var wolf := get_node_or_null("WildWolf")
	var hud := get_node_or_null("HUD")

	if player != null:
		player.add_to_group("player")

	if wolf != null and player != null and wolf.has_method("set_target"):
		wolf.set_target(player)

	if hud != null and player != null and player.has_node("HealthComponent"):
		var health_component := player.get_node("HealthComponent")
		health_component.health_changed.connect(_update_hud_health)
		_update_hud_health(health_component.current_hp, health_component.max_hp)


func _update_hud_health(current_hp: int, max_hp: int) -> void:
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("set_health"):
		hud.set_health(current_hp, max_hp)
		return

	var hp_label := get_node_or_null("HUD/BottomPanel/LeftFrame/HpLabel") as Label
	var hp_bar := get_node_or_null("HUD/BottomPanel/LeftFrame/HpBar") as ColorRect
	if hp_label != null:
		hp_label.text = "HP %d/%d" % [current_hp, max_hp]
	if hp_bar != null:
		var ratio := clampf(float(current_hp) / float(max_hp), 0.0, 1.0) if max_hp > 0 else 0.0
		hp_bar.size.x = 138.0 * ratio


# --- Live gameplay session: inventory, equipment, loot pickup, equip ---------
func _setup_game_session() -> void:
	_game_data = GameDataScript.new()
	add_child(_game_data)
	if not _game_data.load_all():
		push_warning("game session: failed to load game data")
	_inventory = InventoryModelScript.new()
	add_child(_inventory)
	_inventory.setup(_game_data)
	_equipment = EquipmentModelScript.new()
	add_child(_equipment)
	_equipment.setup(_game_data, _inventory)
	add_to_group("game_session")

	# Starting kit so the pickup/equip loop is demonstrable from the first minute.
	_inventory.add_gold(20)
	_inventory.add_item("wooden_sword", 1)
	_inventory.add_item("small_health_potion", 2)

	_capture_base_stats()
	_connect_inventory_ui()
	_refresh_ui()


func _capture_base_stats() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return
	_base_attack = int(player.get("attack"))
	_base_defense = int(player.get("defense"))
	_base_max_hp = int(player.get("max_hp"))


func _connect_inventory_ui() -> void:
	var ui := get_node_or_null("UIRoot")
	if ui == null or not ui.has_method("get_inventory_panel"):
		return
	var panel: Control = ui.get_inventory_panel()
	if panel != null and panel.has_signal("item_activated"):
		if not panel.item_activated.is_connected(_on_inventory_item_activated):
			panel.item_activated.connect(_on_inventory_item_activated)


func get_item_icon_index(item_id: String) -> int:
	if _game_data == null:
		return 0
	return int(_game_data.get_item(item_id).get("icon_index", 0))


func collect_drop(dropped: Node) -> bool:
	if _inventory == null or dropped == null or not dropped.has_method("pickup"):
		return false
	var collected: bool = dropped.pickup(_inventory)
	if collected:
		_refresh_ui()
	return collected


func _on_inventory_item_activated(item_id: String) -> void:
	if _inventory == null or _equipment == null or item_id.is_empty():
		return
	if _inventory.is_equipment(item_id):
		if _equipment.equip(item_id):
			_apply_equipment_stats()
			_refresh_ui()
		return
	if String(_game_data.get_item(item_id).get("type", "")) == "consumable":
		_use_consumable(item_id)


func _use_consumable(item_id: String) -> void:
	var effect: Dictionary = _game_data.get_item(item_id).get("effect", {}) as Dictionary
	var heal_amount := int(effect.get("heal_hp", 0))
	if heal_amount <= 0:
		return
	var player := get_node_or_null("Player")
	var health_component := player.get_node_or_null("HealthComponent") if player != null else null
	if health_component == null:
		return
	if not _inventory.remove_item(item_id, 1):
		return
	health_component.heal(heal_amount)
	_refresh_ui()


func _apply_equipment_stats() -> void:
	var attack := _base_attack
	var defense := _base_defense
	var max_hp := _base_max_hp
	for slot in _equipment.get_equipped_items():
		var item_id: String = _equipment.get_equipped_item_id(slot)
		if item_id.is_empty():
			continue
		var stats: Dictionary = _game_data.get_item(item_id).get("stats", {}) as Dictionary
		attack += int(stats.get("attack", 0))
		defense += int(stats.get("defense", 0))
		max_hp += int(stats.get("max_hp", 0))

	var player := get_node_or_null("Player")
	if player == null:
		return
	player.set("attack", attack)
	var hitbox := player.get_node_or_null("AttackHitbox")
	if hitbox != null:
		hitbox.set("attack", attack)
	var health_component := player.get_node_or_null("HealthComponent")
	if health_component != null:
		health_component.max_hp = max_hp
		health_component.defense = defense
		health_component.current_hp = mini(health_component.current_hp, max_hp)
		health_component.health_changed.emit(health_component.current_hp, max_hp)


func _refresh_ui() -> void:
	var ui := get_node_or_null("UIRoot")
	if ui != null:
		if ui.has_method("set_live_inventory"):
			ui.set_live_inventory(_build_inventory_display())
		if ui.has_method("set_live_equipment"):
			ui.set_live_equipment(_build_equipment_display(), _build_stats())
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_method("set_gold"):
		hud.set_gold(_inventory.gold)


func _build_inventory_display() -> Array:
	var display: Array = []
	for entry in _inventory.get_entries():
		var item_id := String(entry.get("item_id", ""))
		var data: Dictionary = _game_data.get_item(item_id).duplicate(true)
		data["item_id"] = item_id
		data["quantity"] = int(entry.get("quantity", 1))
		display.append(data)
	return display


func _build_equipment_display() -> Dictionary:
	var display: Dictionary = {}
	for slot in _equipment.get_equipped_items():
		var item_id: String = _equipment.get_equipped_item_id(slot)
		if item_id.is_empty():
			display[slot] = {}
			continue
		var data: Dictionary = _game_data.get_item(item_id).duplicate(true)
		data["item_id"] = item_id
		display[slot] = data
	return display


func _build_stats() -> Dictionary:
	var attack := _base_attack
	var defense := _base_defense
	var max_hp := _base_max_hp
	for slot in _equipment.get_equipped_items():
		var item_id: String = _equipment.get_equipped_item_id(slot)
		if item_id.is_empty():
			continue
		var stats: Dictionary = _game_data.get_item(item_id).get("stats", {}) as Dictionary
		attack += int(stats.get("attack", 0))
		defense += int(stats.get("defense", 0))
		max_hp += int(stats.get("max_hp", 0))
	return {"attack": attack, "defense": defense, "max_hp": max_hp, "max_mp": 40}
