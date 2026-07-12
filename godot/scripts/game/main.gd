extends Node2D

const GameDataScript := preload("res://scripts/data/game_data.gd")
const InventoryModelScript := preload("res://scripts/inventory/inventory_model.gd")
const EquipmentModelScript := preload("res://scripts/inventory/equipment_model.gd")
const JsonDataLoader := preload("res://scripts/data/json_data_loader.gd")

var _game_data: Node = null
var _inventory: Node = null
var _equipment: Node = null
var _base_attack: int = 12
var _base_defense: int = 2
var _base_max_hp: int = 100
var _skill_bar: Array = []
var _player_level: int = 1
var _player_exp: int = 0
var _player_exp_max: int = 20
var _interact_prompt: Label = null
const NPC_INTERACT_RANGE := 260.0

var _transition_prompt: Label = null
var _transition_cooldown: float = 0.0
var _maps_cache: Array = []
const TRANSITION_RANGE := 150.0
const TRANSITION_COOLDOWN := 1.2

const ItemIconsSheet := preload("res://assets/items/item_icons_sheet.png")
const QUICK_SLOT_COUNT := 6

# Consumable quick bar (keys 1-6): each entry is an item_id reference (or "").
var _quick_items: Array = ["", "", "", "", "", ""]
# Cursor-carry state: {} when empty, else {"item_id": String, "source": "inventory"|"equip", "slot": String}.
var _carried: Dictionary = {}
var _cursor_layer: CanvasLayer = null
var _cursor_icon: TextureRect = null
var _hint_label: Label = null
var _hint_time_left: float = 0.0


func _ready() -> void:
	print("Pixel Dragon City v0.6 swordsman skills build loaded")
	_setup_game_session()
	_setup_v05_map_flow()
	_connect_player_interaction()
	_connect_combat_prototype()
	_connect_player_death()
	_setup_skills()


func _unhandled_input(event: InputEvent) -> void:
	# UI panel hotkeys: I/B = inventory, C = character (equipment + stats), Esc = close.
	var ui := get_node_or_null("UIRoot")
	if ui == null:
		return
	if event.is_action_pressed("open_inventory"):
		_refresh_ui()
		ui.toggle_inventory()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_character"):
		_refresh_ui()
		ui.toggle_equipment()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_skills"):
		ui.set_skills(_game_data.get_skills_for_class("swordsman") if _game_data != null else [])
		ui.toggle_skills()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_quests"):
		ui.set_quests(_build_quest_list())
		ui.toggle_quests()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("open_map"):
		var map_manager := get_node_or_null("MapManager")
		var current_id: String = map_manager.current_map_id if map_manager != null else ""
		ui.set_map(_load_json_array("res://../data/maps.json"), current_id)
		ui.toggle_map()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		if is_carrying():
			cancel_carry()
		elif ui.has_method("close_active_panel"):
			ui.close_active_panel()
		get_viewport().set_input_as_handled()
	else:
		for i in range(QUICK_SLOT_COUNT):
			if event.is_action_pressed("use_item_%d" % (i + 1)):
				_use_quick_item(i)
				get_viewport().set_input_as_handled()
				return


func _process(delta: float) -> void:
	_update_cursor_visuals(delta)
	_update_target_info()
	if _transition_cooldown > 0.0:
		_transition_cooldown -= delta
	_update_transition_prompt()
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
	_update_interact_prompt()


func _update_interact_prompt() -> void:
	# Floating "按 E 交谈" hint above the nearest NPC within interact range.
	var map_manager := get_node_or_null("MapManager")
	var player := get_node_or_null("Player") as Node2D
	if map_manager == null or player == null:
		_hide_interact_prompt()
		return
	var current_map: Node = map_manager.get_current_map()
	if current_map == null or not current_map.has_node("Npcs"):
		_hide_interact_prompt()
		return

	var nearest: Node2D = null
	var nearest_distance := INF
	for npc in current_map.get_node("Npcs").get_children():
		if not npc is Node2D or not npc.has_method("interact"):
			continue
		var distance := player.global_position.distance_to(npc.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = npc

	if nearest == null or nearest_distance > NPC_INTERACT_RANGE:
		_hide_interact_prompt()
		return

	_ensure_interact_prompt(current_map)
	_interact_prompt.global_position = nearest.global_position + Vector2(-48, -128)
	_interact_prompt.visible = true


func _ensure_interact_prompt(map_node: Node) -> void:
	if _interact_prompt != null and is_instance_valid(_interact_prompt):
		if _interact_prompt.get_parent() != map_node:
			_interact_prompt.get_parent().remove_child(_interact_prompt)
			map_node.add_child(_interact_prompt)
		return
	_interact_prompt = Label.new()
	_interact_prompt.text = "按 E 交谈"
	_interact_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_interact_prompt.custom_minimum_size = Vector2(96, 0)
	_interact_prompt.z_index = 50
	_interact_prompt.add_theme_color_override("font_color", Color(1, 0.93, 0.6))
	_interact_prompt.add_theme_font_size_override("font_size", 14)
	map_node.add_child(_interact_prompt)


func _hide_interact_prompt() -> void:
	if _interact_prompt != null and is_instance_valid(_interact_prompt):
		_interact_prompt.visible = false


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
	for i in range(4):
		hud.set_skill_slot(i, _skill_bar[i] if i < _skill_bar.size() else {})
	_refresh_quick_slots()
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


const DROP_PICKUP_RANGE := 120.0


func _try_pickup_nearest_drop(player: Node2D) -> bool:
	var nearest: Node = null
	var best := INF
	for drop in get_tree().get_nodes_in_group("dropped_item"):
		if not drop is Node2D or not drop.has_method("pickup"):
			continue
		var d: float = player.global_position.distance_to(drop.global_position)
		if d < best:
			best = d
			nearest = drop
	if nearest != null and best <= DROP_PICKUP_RANGE:
		return collect_drop(nearest)
	return false


func _connect_player_death() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return
	var hc := player.get_node_or_null("HealthComponent")
	if hc != null and hc.has_signal("died") and not hc.died.is_connected(_on_player_died):
		hc.died.connect(_on_player_died)


func _on_player_died(_source: Variant) -> void:
	# Respawn in the village at full HP, with a red flash + message for feedback.
	var map_manager := get_node_or_null("MapManager")
	if map_manager != null:
		map_manager.load_map("greenwood_village", "village_spawn")
	var player := get_node_or_null("Player")
	var hc := player.get_node_or_null("HealthComponent") if player != null else null
	if hc != null:
		if hc.has_method("revive"):
			hc.revive()
		else:
			hc.current_hp = hc.max_hp
			hc.health_changed.emit(hc.current_hp, hc.max_hp)
	_play_death_flash()


func _play_death_flash() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 200
	add_child(layer)
	var rect := ColorRect.new()
	rect.color = Color(0.45, 0.0, 0.0, 0.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	var label := Label.new()
	label.text = "你已倒下 · 返回青木村"
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(1, 0.85, 0.8))
	label.modulate.a = 0.0
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	var tween := create_tween()
	tween.tween_property(rect, "color:a", 0.7, 0.25)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.25)
	tween.tween_interval(0.8)
	tween.tween_property(rect, "color:a", 0.0, 0.6)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 0.6)
	tween.tween_callback(layer.queue_free)


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

	# A nearby map transition takes priority over NPC dialogue.
	var player_node := get_node_or_null("Player") as Node2D
	if player_node != null and _transition_cooldown <= 0.0:
		var transition := _nearest_transition(player_node)
		if not transition.is_empty() and float(transition.get("distance", INF)) <= TRANSITION_RANGE:
			map_manager.load_map(String(transition.get("target_map_id", "")), String(transition.get("target_spawn_id", "")))
			return

	# Pick up the nearest dropped item in reach.
	if player_node != null and _try_pickup_nearest_drop(player_node):
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
	# Block transition re-trigger briefly so spawning next to a return point can't bounce.
	_transition_cooldown = TRANSITION_COOLDOWN


func _connect_enemy_deaths(map_node: Node) -> void:
	if map_node == null or not map_node.has_node("Enemies"):
		return
	var quest_manager := get_node_or_null("QuestManager")
	var player := get_node_or_null("Player") as Node2D
	if player != null:
		player.add_to_group("player")

	for enemy in map_node.get_node("Enemies").get_children():
		if not enemy is Node:
			continue
		enemy.add_to_group("enemy")
		# Aggro: map-spawned enemies need their target wired to the live player.
		if player != null and enemy.has_method("set_target"):
			enemy.set_target(player)
		# Data-driven attack speed per monster.
		var mdata := _monster_data(String(enemy.get("monster_id")))
		if mdata.has("attack_cooldown") and "attack_cooldown" in enemy:
			enemy.attack_cooldown = float(mdata["attack_cooldown"])
		var health_component := enemy.get_node_or_null("HealthComponent")
		if health_component == null or not health_component.has_signal("died"):
			continue
		if quest_manager != null:
			var died_callback := Callable(self, "_on_enemy_died").bind(enemy)
			if not health_component.died.is_connected(died_callback):
				health_component.died.connect(died_callback)


func _on_enemy_died(_source: Variant, enemy: Node) -> void:
	var monster_id := String(enemy.get("monster_id"))
	_award_kill_rewards(monster_id)

	var quest_manager := get_node_or_null("QuestManager")
	if quest_manager != null:
		if monster_id == "wild_wolf" and quest_manager.has_method("record_wild_wolf_defeated"):
			quest_manager.record_wild_wolf_defeated()
		elif monster_id == "black_wolf_leader" and quest_manager.has_method("record_black_wolf_leader_defeated"):
			quest_manager.record_black_wolf_leader_defeated()


func _exp_for_level(level: int) -> int:
	return 20 + (maxi(1, level) - 1) * 15


func _award_kill_rewards(monster_id: String) -> void:
	var data := _monster_data(monster_id)
	var gold := int(data.get("gold", 0))
	if gold > 0 and _inventory != null:
		_inventory.add_gold(gold)
	_player_exp += maxi(0, int(data.get("exp", 0)))
	while _player_exp >= _player_exp_max:
		_player_exp -= _player_exp_max
		_player_level += 1
		_player_exp_max = _exp_for_level(_player_level)
		_on_level_up()
	_update_progression_hud()
	_refresh_ui()


func _on_level_up() -> void:
	# Each level makes the swordsman a bit tougher, and fully heals on ding.
	_base_attack += 2
	_base_max_hp += 12
	_apply_equipment_stats()
	var player := get_node_or_null("Player")
	var hc := player.get_node_or_null("HealthComponent") if player != null else null
	if hc != null and hc.has_method("revive"):
		hc.revive()


func _update_progression_hud() -> void:
	var hud := get_node_or_null("HUD")
	if hud == null:
		return
	hud.set_level(_player_level)
	hud.set_experience(_player_exp, _player_exp_max)


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
	_player_exp_max = _exp_for_level(_player_level)
	_update_progression_hud()


func _capture_base_stats() -> void:
	var player := get_node_or_null("Player")
	if player == null:
		return
	_base_attack = int(player.get("attack"))
	_base_defense = int(player.get("defense"))
	_base_max_hp = int(player.get("max_hp"))


func _connect_inventory_ui() -> void:
	var ui := get_node_or_null("UIRoot")
	if ui == null:
		return
	var inv: Control = ui.get_inventory_panel() if ui.has_method("get_inventory_panel") else null
	if inv != null and inv.has_signal("slot_clicked") and not inv.slot_clicked.is_connected(_on_inventory_slot_clicked):
		inv.slot_clicked.connect(_on_inventory_slot_clicked)
	var equip := ui.get_node_or_null("EquipmentPanel")
	if equip != null and equip.has_signal("equip_slot_clicked") and not equip.equip_slot_clicked.is_connected(_on_equip_slot_clicked):
		equip.equip_slot_clicked.connect(_on_equip_slot_clicked)
	var hud := get_node_or_null("HUD")
	if hud != null and hud.has_signal("quick_slot_clicked") and not hud.quick_slot_clicked.is_connected(_on_quick_slot_clicked):
		hud.quick_slot_clicked.connect(_on_quick_slot_clicked)


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


# --- Map transitions (walk to the edge, press E) -----------------------------
func _get_maps() -> Array:
	if _maps_cache.is_empty():
		_maps_cache = _load_json_array("res://../data/maps.json")
	return _maps_cache


func _map_display_name(map_id: String) -> String:
	for map in _get_maps():
		if map is Dictionary and String(map.get("id", "")) == map_id:
			return String(map.get("name", map_id))
	return map_id


func _to_pascal(snake: String) -> String:
	var out := ""
	for part in snake.split("_", false):
		if not part.is_empty():
			out += part.substr(0, 1).to_upper() + part.substr(1)
	return out


func _nearest_transition(player: Node2D) -> Dictionary:
	var map_manager := get_node_or_null("MapManager")
	if map_manager == null:
		return {}
	var current_map: Node = map_manager.get_current_map()
	if current_map == null or not current_map.has_node("TransitionPoints"):
		return {}

	var transitions: Array = []
	for map in _get_maps():
		if map is Dictionary and String(map.get("id", "")) == map_manager.current_map_id:
			transitions = map.get("transitions", [])
			break

	var best: Dictionary = {}
	var best_distance := INF
	for transition in transitions:
		if not transition is Dictionary:
			continue
		var target_id := String(transition.get("target_map_id", ""))
		var marker := current_map.get_node_or_null("TransitionPoints/To%s" % _to_pascal(target_id)) as Node2D
		if marker == null:
			continue
		var distance: float = player.global_position.distance_to(marker.global_position)
		if distance < best_distance:
			best_distance = distance
			best = {
				"marker": marker,
				"target_map_id": target_id,
				"target_spawn_id": String(transition.get("target_spawn_id", "")),
				"name": _map_display_name(target_id),
				"distance": distance,
			}
	return best


func _update_transition_prompt() -> void:
	var player := get_node_or_null("Player") as Node2D
	if player == null or _transition_cooldown > 0.0:
		_hide_transition_prompt()
		return
	var transition := _nearest_transition(player)
	if transition.is_empty() or float(transition.get("distance", INF)) > TRANSITION_RANGE:
		_hide_transition_prompt()
		return
	var marker: Node2D = transition.get("marker")
	_ensure_transition_prompt(marker.get_parent())
	_transition_prompt.text = "按 E 前往%s" % String(transition.get("name", ""))
	_transition_prompt.global_position = marker.global_position + Vector2(-60, -40)
	_transition_prompt.visible = true


func _ensure_transition_prompt(parent: Node) -> void:
	if _transition_prompt != null and is_instance_valid(_transition_prompt):
		if _transition_prompt.get_parent() != parent:
			_transition_prompt.get_parent().remove_child(_transition_prompt)
			parent.add_child(_transition_prompt)
		return
	_transition_prompt = Label.new()
	_transition_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_transition_prompt.custom_minimum_size = Vector2(120, 0)
	_transition_prompt.z_index = 50
	_transition_prompt.add_theme_color_override("font_color", Color(0.7, 0.95, 1))
	_transition_prompt.add_theme_font_size_override("font_size", 14)
	parent.add_child(_transition_prompt)


func _hide_transition_prompt() -> void:
	if _transition_prompt != null and is_instance_valid(_transition_prompt):
		_transition_prompt.visible = false


# --- Bottom-center target info -----------------------------------------------
var _monster_data_cache: Dictionary = {}
const TARGET_INFO_RANGE := 520.0


func _monster_data(monster_id: String) -> Dictionary:
	if _monster_data_cache.is_empty():
		for monster in _load_json_array("res://../data/monsters.json"):
			if monster is Dictionary:
				_monster_data_cache[String(monster.get("id", ""))] = monster
	return _monster_data_cache.get(monster_id, {})


func _update_target_info() -> void:
	var hud := get_node_or_null("HUD")
	if hud == null or not hud.has_method("set_target"):
		return
	var map_manager := get_node_or_null("MapManager")
	var player := get_node_or_null("Player") as Node2D
	if map_manager == null or player == null:
		hud.clear_target()
		return
	var current_map: Node = map_manager.get_current_map()
	if current_map == null or not current_map.has_node("Enemies"):
		hud.clear_target()
		return

	var nearest: Node = null
	var nearest_hc: Node = null
	var nearest_distance := INF
	for enemy in current_map.get_node("Enemies").get_children():
		if not enemy is Node2D:
			continue
		var hc := enemy.get_node_or_null("HealthComponent")
		if hc == null or int(hc.current_hp) <= 0:
			continue
		var distance: float = player.global_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = enemy
			nearest_hc = hc

	if nearest == null or nearest_distance > TARGET_INFO_RANGE:
		hud.clear_target()
		return
	var monster_id := String(nearest.get("monster_id"))
	var info := _monster_data(monster_id)
	# Monsters have no mana; the MP bar reads 0/0 for now.
	hud.set_target(String(info.get("name", monster_id)), int(info.get("level", 0)), int(nearest_hc.current_hp), int(nearest_hc.max_hp), 0, 0)


# --- Info panel data assembly (skills / quests / map) ------------------------
func _load_json_array(path: String) -> Array:
	var loader := JsonDataLoader.new()
	var data: Variant = loader.load_json(path)
	return data if data is Array else []


func _build_quest_list() -> Array:
	var quest_meta := _load_json_array("res://../data/quests.json")
	var quest_manager := get_node_or_null("QuestManager")
	var states: Dictionary = quest_manager.get_all_quest_states() if quest_manager != null else {}
	var result: Array = []
	for quest in quest_meta:
		if not quest is Dictionary:
			continue
		var entry: Dictionary = quest.duplicate(true)
		entry["state"] = String(states.get(String(quest.get("id", "")), "not_started"))
		result.append(entry)
	return result


# --- Cursor-carry item interaction -------------------------------------------
func is_carrying() -> bool:
	return not _carried.is_empty()


func cancel_carry() -> void:
	# Carried items are references only (the model was never mutated), so cancel just clears state.
	_carried = {}
	_clear_carry_visual()


func _on_inventory_slot_clicked(index: int, item_id: String, double_click: bool) -> void:
	if double_click and not item_id.is_empty():
		# Double-click uses/equips directly; also reconciles the pick-up from the first click.
		cancel_carry()
		_use_or_equip(item_id)
		return
	if is_carrying():
		# Placing a carried item back onto the bag just cancels the carry.
		cancel_carry()
		return
	if not item_id.is_empty():
		_pick_up(item_id, "inventory", str(index))


func _on_equip_slot_clicked(slot_id: String, item_id: String, double_click: bool) -> void:
	if is_carrying():
		var carried_id: String = _carried.get("item_id", "")
		if _game_data.get_item_slot(carried_id) == slot_id:
			if _equipment.equip(carried_id):
				_apply_equipment_stats()
				cancel_carry()
				_refresh_ui()
		else:
			_show_hint("无法装备到此处")
		return
	if not item_id.is_empty():
		# Single or double click on an equipped item takes it off, back to the bag.
		if _equipment.unequip(slot_id):
			_apply_equipment_stats()
			_refresh_ui()


func _on_quick_slot_clicked(index: int, double_click: bool) -> void:
	if is_carrying():
		var carried_id: String = _carried.get("item_id", "")
		if String(_game_data.get_item(carried_id).get("type", "")) == "consumable":
			_quick_items[index] = carried_id
			cancel_carry()
			_refresh_quick_slots()
		else:
			_show_hint("只能放入消耗品")
		return
	_use_quick_item(index)


func _pick_up(item_id: String, source: String, slot: String) -> void:
	_carried = {"item_id": item_id, "source": source, "slot": slot}
	_ensure_cursor_layer()
	_apply_cursor_icon(int(_game_data.get_item(item_id).get("icon_index", -1)))
	_cursor_icon.visible = true


func _use_or_equip(item_id: String) -> void:
	if _inventory == null or _equipment == null or item_id.is_empty():
		return
	if _inventory.is_equipment(item_id):
		if _equipment.equip(item_id):
			_apply_equipment_stats()
			_refresh_ui()
		return
	if String(_game_data.get_item(item_id).get("type", "")) == "consumable":
		_use_consumable(item_id)
		return
	_show_hint("无法使用")


func _use_quick_item(index: int) -> void:
	if index < 0 or index >= _quick_items.size():
		return
	var item_id: String = _quick_items[index]
	if item_id.is_empty():
		return
	if _inventory.count_item(item_id) <= 0:
		_show_hint("没有可用的%s" % String(_game_data.get_item(item_id).get("name", "物品")))
		return
	if String(_game_data.get_item(item_id).get("type", "")) == "consumable":
		_use_consumable(item_id)


func _refresh_quick_slots() -> void:
	var hud := get_node_or_null("HUD")
	if hud == null or not hud.has_method("set_item_slot"):
		return
	for i in range(QUICK_SLOT_COUNT):
		var item_id: String = _quick_items[i] if i < _quick_items.size() else ""
		if item_id.is_empty() or _inventory == null:
			hud.set_item_slot(i, {})
			continue
		var data: Dictionary = _game_data.get_item(item_id).duplicate(true)
		data["item_id"] = item_id
		data["quantity"] = _inventory.count_item(item_id)
		hud.set_item_slot(i, data)


# --- Cursor visuals + floating hint ------------------------------------------
func _ensure_cursor_layer() -> void:
	if _cursor_layer != null and is_instance_valid(_cursor_layer):
		return
	_cursor_layer = CanvasLayer.new()
	_cursor_layer.layer = 100
	add_child(_cursor_layer)
	_cursor_icon = TextureRect.new()
	_cursor_icon.custom_minimum_size = Vector2(40, 40)
	_cursor_icon.size = Vector2(40, 40)
	_cursor_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor_icon.visible = false
	_cursor_layer.add_child(_cursor_icon)
	_hint_label = Label.new()
	_hint_label.add_theme_color_override("font_color", Color(1, 0.6, 0.5))
	_hint_label.add_theme_font_size_override("font_size", 16)
	_hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint_label.visible = false
	_cursor_layer.add_child(_hint_label)


func _apply_cursor_icon(icon_index: int) -> void:
	if icon_index < 0:
		_cursor_icon.texture = null
		return
	var atlas := AtlasTexture.new()
	atlas.atlas = ItemIconsSheet
	atlas.region = Rect2(icon_index * 32, 0, 32, 32)
	_cursor_icon.texture = atlas
	_cursor_icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _clear_carry_visual() -> void:
	if _cursor_icon != null and is_instance_valid(_cursor_icon):
		_cursor_icon.visible = false


func _show_hint(text: String) -> void:
	_ensure_cursor_layer()
	_hint_label.text = text
	_hint_label.visible = true
	_hint_time_left = 1.2


func _update_cursor_visuals(delta: float) -> void:
	if _cursor_layer == null or not is_instance_valid(_cursor_layer):
		return
	var mouse := get_viewport().get_mouse_position()
	if _cursor_icon.visible:
		_cursor_icon.global_position = mouse + Vector2(-20, -20)
	if _hint_label.visible:
		_hint_label.global_position = mouse + Vector2(12, -28)
		_hint_time_left -= delta
		if _hint_time_left <= 0.0:
			_hint_label.visible = false


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
	_refresh_quick_slots()


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
