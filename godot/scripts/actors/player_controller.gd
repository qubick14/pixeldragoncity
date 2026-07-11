extends CharacterBody2D

signal interact_requested
signal mana_changed(current_mp: int, max_mp: int)
signal skill_used(skill_id: String, cooldown: float)

const AttackAtlas := preload("res://assets/sprites/swordsman/swordsman_attack_pixel_atlas.png")

@export var walk_speed: float = 140.0
@export var run_speed: float = 220.0
@export var pointer_stop_distance: float = 8.0
@export var visual_scale: float = 0.82
@export var walk_atlas_columns: int = 4
@export var walk_atlas_rows: int = 9
@export var max_hp: int = 100
@export var max_mp: int = 40
@export var mp_regen: float = 4.0
@export var attack: int = 12
@export var defense: int = 2
@export var attack_cooldown: float = 0.55
@export var attack_active_time: float = 0.12
@export var attack_anim_time: float = 0.3

enum AnimationState {
	IDLE,
	WALK,
	ATTACK,
}

var animation_state: AnimationState = AnimationState.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var pointer_move_enabled: bool = false
var pointer_run_enabled: bool = false
var pointer_continuous_enabled: bool = false
var pointer_target: Vector2 = Vector2.ZERO

var current_mp: int = 40

var _animation_time: float = 0.0
var _generated_sprite_base_position := Vector2.ZERO
var _attack_active_timer: float = 0.0
var _attack_anim_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0
var _walk_texture: Texture2D = null
var _mp_regen_accum: float = 0.0
var _skill_bar: Array = []
var _skill_cooldowns: Dictionary = {}

@onready var visual_root: Node2D = $VisualRoot
@onready var generated_sprite: Sprite2D = $VisualRoot/GeneratedSprite
@onready var attack_slash: Node2D = $VisualRoot/AttackSlash
@onready var health_component: Node = $HealthComponent
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var health_bar: Control = $HealthBar


func _ready() -> void:
	_generated_sprite_base_position = generated_sprite.position
	_walk_texture = generated_sprite.texture
	health_component.setup(max_hp, defense)
	attack_hitbox.setup(self, attack)
	_set_attack_hitbox_enabled(false)
	health_bar.bind(health_component)
	_apply_visual_facing()
	_update_generated_sprite_region()
	current_mp = max_mp
	mana_changed.emit(current_mp, max_mp)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			start_pointer_move(get_global_mouse_position(), false, false)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			start_pointer_move(get_global_mouse_position(), true, false)
	elif _is_action_event(event, "attack_primary"):
		start_attack()
	elif _is_action_event(event, "skill_slot_1"):
		use_skill_slot(0)
	elif _is_action_event(event, "skill_slot_2"):
		use_skill_slot(1)
	elif _is_action_event(event, "interact"):
		interact_requested.emit()


func _physics_process(delta: float) -> void:
	_update_attack_timers(delta)
	_update_skill_state(delta)
	var input_vector := _get_keyboard_input()

	if input_vector != Vector2.ZERO:
		stop_pointer_move()
	else:
		_update_continuous_pointer_move()
		input_vector = _get_pointer_input()

	velocity = input_vector * get_active_move_speed()
	_update_animation_state(input_vector)
	move_and_slide()
	_update_placeholder_animation(delta)


func start_pointer_move(target_position: Vector2, should_run: bool, continuous: bool) -> void:
	pointer_target = target_position
	pointer_move_enabled = true
	pointer_run_enabled = should_run
	pointer_continuous_enabled = continuous


func stop_pointer_move() -> void:
	pointer_move_enabled = false
	pointer_run_enabled = false
	pointer_continuous_enabled = false


func get_active_move_speed() -> float:
	return run_speed if pointer_run_enabled else walk_speed


func start_attack() -> bool:
	# The light attack maps to the first skill on the bar (basic_slash) when one
	# is equipped, so weapon scaling and cooldown flow through the skill system.
	if not _skill_bar.is_empty():
		return use_skill_slot(0)
	return _perform_attack(attack, attack_cooldown)


func set_skill_bar(skills: Array) -> void:
	_skill_bar = skills.duplicate(true)


func get_skill_bar() -> Array:
	return _skill_bar.duplicate(true)


func use_skill_slot(index: int) -> bool:
	if index < 0 or index >= _skill_bar.size():
		return false
	return use_skill(_skill_bar[index])


func use_skill(skill: Dictionary) -> bool:
	if skill.is_empty() or _attack_active_timer > 0.0:
		return false
	var skill_id := String(skill.get("id", ""))
	if get_skill_cooldown_remaining(skill_id) > 0.0:
		return false
	var mp_cost := int(skill.get("mp_cost", 0))
	if current_mp < mp_cost:
		return false

	var multiplier := float(skill.get("multiplier", 1.0))
	var damage := maxi(1, int(round(float(attack) * multiplier)))
	var cooldown := float(skill.get("cooldown", attack_cooldown))
	if not _perform_attack(damage, cooldown):
		return false

	if mp_cost > 0:
		current_mp = maxi(0, current_mp - mp_cost)
		mana_changed.emit(current_mp, max_mp)
	_skill_cooldowns[skill_id] = cooldown
	skill_used.emit(skill_id, cooldown)
	return true


func get_skill_cooldown_remaining(skill_id: String) -> float:
	return float(_skill_cooldowns.get(skill_id, 0.0))


func _perform_attack(damage: int, cooldown: float) -> bool:
	if _attack_active_timer > 0.0:
		return false

	_attack_active_timer = attack_active_time
	_attack_anim_timer = attack_anim_time
	_attack_cooldown_timer = cooldown
	animation_state = AnimationState.ATTACK
	if attack_hitbox != null:
		attack_hitbox.attack = maxi(1, damage)
	_position_attack_hitbox()
	_apply_attack_visual_offset()
	_set_attack_hitbox_enabled(true)
	return true


func _update_skill_state(delta: float) -> void:
	for skill_id in _skill_cooldowns.keys():
		var remaining := float(_skill_cooldowns[skill_id]) - delta
		if remaining <= 0.0:
			_skill_cooldowns.erase(skill_id)
		else:
			_skill_cooldowns[skill_id] = remaining

	if current_mp < max_mp:
		_mp_regen_accum += mp_regen * delta
		var whole := int(floor(_mp_regen_accum))
		if whole > 0:
			_mp_regen_accum -= float(whole)
			current_mp = mini(max_mp, current_mp + whole)
			mana_changed.emit(current_mp, max_mp)


func _get_keyboard_input() -> Vector2:
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _is_action_event(event: InputEvent, action_name: String) -> bool:
	if event.is_action_pressed(action_name):
		return true
	if event is InputEventAction:
		var action_event := event as InputEventAction
		return action_event.action == action_name and action_event.pressed
	return false


func _update_continuous_pointer_move() -> void:
	var left_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var right_pressed := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)

	if right_pressed:
		start_pointer_move(get_global_mouse_position(), true, true)
	elif left_pressed:
		start_pointer_move(get_global_mouse_position(), false, true)
	elif pointer_continuous_enabled:
		stop_pointer_move()


func _get_pointer_input() -> Vector2:
	if not pointer_move_enabled:
		return Vector2.ZERO

	var to_target := pointer_target - global_position
	if to_target.length() <= pointer_stop_distance:
		stop_pointer_move()
		return Vector2.ZERO

	return to_target.normalized()


func _update_animation_state(input_vector: Vector2) -> void:
	if _attack_anim_timer > 0.0:
		animation_state = AnimationState.ATTACK
		if input_vector != Vector2.ZERO:
			facing_direction = input_vector
			_apply_visual_facing()
			_position_attack_hitbox()
		return

	if input_vector == Vector2.ZERO:
		animation_state = AnimationState.IDLE
		return

	animation_state = AnimationState.WALK
	facing_direction = input_vector
	_apply_visual_facing()
	_position_attack_hitbox()


func _update_attack_timers(delta: float) -> void:
	if _attack_cooldown_timer > 0.0:
		_attack_cooldown_timer = maxf(0.0, _attack_cooldown_timer - delta)

	if _attack_anim_timer > 0.0:
		_attack_anim_timer = maxf(0.0, _attack_anim_timer - delta)

	if _attack_active_timer <= 0.0:
		return

	_attack_active_timer = maxf(0.0, _attack_active_timer - delta)
	if _attack_active_timer == 0.0:
		_set_attack_hitbox_enabled(false)
		_hide_attack_slash()


func _position_attack_hitbox() -> void:
	var active_hitbox := _get_attack_hitbox()
	if active_hitbox == null:
		return

	var direction := facing_direction
	if direction.length() < 0.1:
		direction = Vector2.DOWN

	active_hitbox.position = direction.normalized() * 34.0


func _set_attack_hitbox_enabled(is_enabled: bool) -> void:
	var active_hitbox := _get_attack_hitbox()
	if active_hitbox == null:
		return

	active_hitbox.enabled = is_enabled
	active_hitbox.monitoring = is_enabled
	active_hitbox.monitorable = is_enabled


func _get_attack_hitbox() -> Area2D:
	if attack_hitbox != null:
		return attack_hitbox
	if has_node("AttackHitbox"):
		attack_hitbox = get_node("AttackHitbox") as Area2D
	return attack_hitbox


func _apply_visual_facing() -> void:
	visual_root.scale = Vector2(visual_scale, visual_scale)


func _update_placeholder_animation(delta: float) -> void:
	if animation_state == AnimationState.ATTACK:
		_animation_time += delta * 18.0
		_apply_attack_visual_offset()
		_update_generated_sprite_region()
		return

	if animation_state == AnimationState.IDLE:
		_animation_time = 0.0
		visual_root.position = Vector2.ZERO
		_update_generated_sprite_region()
		return

	_animation_time += delta * _get_active_animation_fps()
	visual_root.position.y = -absf(sin(_animation_time)) * (3.0 if pointer_run_enabled else 2.0)
	_update_generated_sprite_region()


func _get_active_animation_fps() -> float:
	return 12.0 if pointer_run_enabled else 8.0


func get_animation_key() -> String:
	var state_name := "idle"
	match animation_state:
		AnimationState.WALK:
			state_name = "walk"
		AnimationState.ATTACK:
			state_name = "attack"
	var direction_name := "center"
	var direction_cell := get_direction_cell(facing_direction)

	match direction_cell:
		Vector2i(0, 0):
			direction_name = "up_left"
		Vector2i(1, 0):
			direction_name = "up"
		Vector2i(2, 0):
			direction_name = "up_right"
		Vector2i(0, 1):
			direction_name = "left"
		Vector2i(2, 1):
			direction_name = "right"
		Vector2i(0, 2):
			direction_name = "down_left"
		Vector2i(1, 2):
			direction_name = "down"
		Vector2i(2, 2):
			direction_name = "down_right"

	return "%s_%s" % [state_name, direction_name]


func _apply_attack_visual_offset() -> void:
	var active_visual_root := _get_visual_root()
	if active_visual_root == null:
		return

	var attack_direction := facing_direction
	if attack_direction.length() < 0.1:
		attack_direction = Vector2.DOWN
	active_visual_root.position = attack_direction.normalized() * 6.0


func _show_attack_slash() -> void:
	var slash := _get_attack_slash()
	if slash == null:
		return

	var attack_direction := facing_direction
	if attack_direction.length() < 0.1:
		attack_direction = Vector2.DOWN

	slash.visible = true
	slash.position = attack_direction.normalized() * 30.0 + Vector2(0, -32)
	slash.rotation = attack_direction.angle()


func _hide_attack_slash() -> void:
	var slash := _get_attack_slash()
	if slash != null:
		slash.visible = false


func _get_attack_slash() -> Node2D:
	if attack_slash != null:
		return attack_slash
	if has_node("VisualRoot/AttackSlash"):
		attack_slash = get_node("VisualRoot/AttackSlash") as Node2D
	return attack_slash


func _get_visual_root() -> Node2D:
	if visual_root != null:
		return visual_root
	if has_node("VisualRoot"):
		visual_root = get_node("VisualRoot") as Node2D
	return visual_root


func get_direction_cell(direction: Vector2) -> Vector2i:
	if direction.length() < 0.1:
		return Vector2i(1, 1)

	var normalized_direction := direction.normalized()
	var x_cell := 1
	var y_cell := 1

	if normalized_direction.x < -0.35:
		x_cell = 0
	elif normalized_direction.x > 0.35:
		x_cell = 2

	if normalized_direction.y < -0.35:
		y_cell = 0
	elif normalized_direction.y > 0.35:
		y_cell = 2

	return Vector2i(x_cell, y_cell)


func _get_generated_sprite() -> Sprite2D:
	if generated_sprite != null:
		return generated_sprite
	if has_node("VisualRoot/GeneratedSprite"):
		generated_sprite = get_node("VisualRoot/GeneratedSprite") as Sprite2D
	return generated_sprite


func _update_generated_sprite_region() -> void:
	var sprite := _get_generated_sprite()
	if sprite == null:
		return
	if _walk_texture == null:
		_walk_texture = sprite.texture

	var attacking := animation_state == AnimationState.ATTACK and _attack_anim_timer > 0.0
	var desired_texture: Texture2D = AttackAtlas if attacking else _walk_texture
	if desired_texture != null and sprite.texture != desired_texture:
		sprite.texture = desired_texture
	if sprite.texture == null:
		return

	var texture_size := sprite.texture.get_size()
	var cell_size := Vector2(texture_size.x / float(walk_atlas_columns), texture_size.y / float(walk_atlas_rows))
	var direction_cell := get_direction_cell(facing_direction)
	var frame_index := 0
	if attacking:
		var progress := 1.0 - (_attack_anim_timer / maxf(attack_anim_time, 0.001))
		frame_index = clampi(int(progress * float(walk_atlas_columns)), 0, walk_atlas_columns - 1)
	elif animation_state == AnimationState.WALK:
		frame_index = int(floor(_animation_time)) % walk_atlas_columns

	var row_index := get_test_atlas_row(direction_cell)
	sprite.flip_h = should_flip_test_atlas_row(direction_cell)
	sprite.position = _generated_sprite_base_position
	sprite.region_rect = Rect2(Vector2(frame_index, row_index) * cell_size, cell_size)


func get_test_atlas_row(direction_cell: Vector2i) -> int:
	match direction_cell:
		Vector2i(1, 2):
			return 0
		Vector2i(0, 2):
			return 1
		Vector2i(0, 1):
			return 2
		Vector2i(0, 0):
			return 3
		Vector2i(1, 0):
			return 4
		Vector2i(2, 0):
			return 5
		Vector2i(2, 1):
			return 6
		Vector2i(2, 2):
			return 7
		_:
			return 8


func should_flip_test_atlas_row(direction_cell: Vector2i) -> bool:
	return false


func get_back_walk_frame_offset(direction_cell: Vector2i, frame_index: int) -> Vector2:
	return Vector2.ZERO
