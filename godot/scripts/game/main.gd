extends Node2D


func _ready() -> void:
	print("Pixel Dragon City v0.2 combat prototype loaded")
	_setup_v05_map_flow()
	_connect_player_interaction()
	_connect_combat_prototype()


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
