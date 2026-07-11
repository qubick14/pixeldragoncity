extends CharacterBody2D

const GameDataScript := preload("res://scripts/data/game_data.gd")
const LootTableScript := preload("res://scripts/loot/loot_table.gd")
const DroppedItemScene := preload("res://scenes/loot/dropped_item.tscn")

@export var max_hp: int = 50
@export var attack: int = 8
@export var defense: int = 1
@export var monster_id: String = "wild_wolf"
@export var move_speed: float = 70.0
@export var aggro_range: float = 280.0
@export var attack_range: float = 42.0
@export var attack_cooldown: float = 0.9
@export var attack_active_time: float = 0.16
@export var hurt_pause: float = 0.18

enum State {
	IDLE,
	CHASE,
	ATTACK,
	HURT,
	DEAD,
}

var current_state: State = State.IDLE
var target: Node2D = null

var _attack_cooldown_timer: float = 0.0
var _attack_active_timer: float = 0.0
var _hurt_timer: float = 0.0
var _combat_initialized: bool = false

@onready var health_component: Node = $HealthComponent
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var health_bar: Control = $HealthBar
@onready var generated_sprite: Sprite2D = $VisualRoot/GeneratedSprite


func _ready() -> void:
	_ensure_combat_initialized()


func _ensure_combat_initialized() -> void:
	if _combat_initialized:
		return

	if health_component == null and has_node("HealthComponent"):
		health_component = get_node("HealthComponent")
	if attack_hitbox == null and has_node("AttackHitbox"):
		attack_hitbox = get_node("AttackHitbox") as Area2D
	if body_collision == null and has_node("CollisionShape2D"):
		body_collision = get_node("CollisionShape2D") as CollisionShape2D
	if health_bar == null and has_node("HealthBar"):
		health_bar = get_node("HealthBar") as Control

	health_component.setup(max_hp, defense)
	if not health_component.damaged.is_connected(_on_damaged):
		health_component.damaged.connect(_on_damaged)
	if not health_component.died.is_connected(_on_died):
		health_component.died.connect(_on_died)
	attack_hitbox.setup(self, attack)
	_set_attack_hitbox_enabled(false)
	health_bar.bind(health_component)
	_combat_initialized = true


func set_target(new_target: Node2D) -> void:
	_ensure_combat_initialized()
	target = new_target


func _physics_process(delta: float) -> void:
	_ensure_combat_initialized()
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		return

	_update_timers(delta)

	if current_state == State.HURT:
		velocity = Vector2.ZERO
		_safe_move_and_slide()
		return

	if target == null:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_safe_move_and_slide()
		return

	var to_target := target.global_position - global_position
	var distance := to_target.length()

	# Face movement/target horizontally (art faces left by default).
	if absf(to_target.x) > 4.0 and generated_sprite != null:
		generated_sprite.flip_h = to_target.x > 0.0

	if distance > aggro_range:
		current_state = State.IDLE
		velocity = Vector2.ZERO
	elif distance <= attack_range:
		current_state = State.ATTACK
		velocity = Vector2.ZERO
		_try_attack(to_target)
	else:
		current_state = State.CHASE
		velocity = to_target.normalized() * move_speed

	_safe_move_and_slide()


func _safe_move_and_slide() -> void:
	if not is_inside_tree():
		return
	if get_world_2d().space.is_valid():
		move_and_slide()


func _update_timers(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)

	if _attack_active_timer > 0.0:
		_attack_active_timer = maxf(0.0, _attack_active_timer - delta)
		if _attack_active_timer == 0.0:
			_set_attack_hitbox_enabled(false)

	if _hurt_timer > 0.0:
		_hurt_timer = maxf(0.0, _hurt_timer - delta)
		if _hurt_timer == 0.0 and current_state == State.HURT:
			current_state = State.IDLE


func _try_attack(to_target: Vector2) -> void:
	if _attack_cooldown_timer > 0.0:
		return

	_attack_cooldown_timer = attack_cooldown
	_attack_active_timer = attack_active_time
	_position_attack_hitbox(to_target)
	_set_attack_hitbox_enabled(true)


func _position_attack_hitbox(to_target: Vector2) -> void:
	var direction := to_target.normalized() if to_target.length() > 0.1 else Vector2.DOWN
	attack_hitbox.position = direction * 30.0


func _set_attack_hitbox_enabled(is_enabled: bool) -> void:
	attack_hitbox.enabled = is_enabled
	attack_hitbox.monitoring = is_enabled
	attack_hitbox.monitorable = is_enabled


func _on_damaged(amount: int, _source: Variant) -> void:
	if health_component.is_dead():
		return

	_spawn_damage_number(amount)
	current_state = State.HURT
	_hurt_timer = hurt_pause


func _on_died(_source: Variant) -> void:
	current_state = State.DEAD
	velocity = Vector2.ZERO
	_set_attack_hitbox_enabled(false)
	$Hurtbox.monitoring = false
	$Hurtbox.monitorable = false
	body_collision.disabled = true
	_spawn_loot()


func _spawn_damage_number(amount: int) -> void:
	var damage_number := Label.new()
	damage_number.set_script(preload("res://scripts/combat/damage_number.gd"))
	damage_number.position = Vector2(-8, -70)
	add_child(damage_number)
	damage_number.setup(amount)


func _spawn_loot() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var game_data := GameDataScript.new()
	if not game_data.load_all():
		game_data.free()
		return

	var loot_table := LootTableScript.new()
	loot_table.setup(game_data)
	var loot: Array = loot_table.roll(monster_id, _seeded_loot_rng())
	var offset_index := 0
	for entry in loot:
		var dropped_item := DroppedItemScene.instantiate()
		dropped_item.name = "DroppedItem%s" % offset_index
		parent_node.add_child(dropped_item)
		dropped_item.global_position = global_position + Vector2(18 * offset_index, 0)
		if entry.get("kind") == "gold":
			dropped_item.setup_gold(int(entry.get("amount", 0)))
		elif entry.get("kind") == "item":
			dropped_item.setup_item(String(entry.get("item_id", "")), int(entry.get("quantity", 1)))
		offset_index += 1

	loot_table.free()
	game_data.free()


func _seeded_loot_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 31.0 + global_position.y * 17.0 + Time.get_ticks_msec())
	return rng
