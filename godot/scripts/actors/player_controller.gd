extends CharacterBody2D

signal interact_requested

@export var walk_speed: float = 140.0
@export var run_speed: float = 220.0
@export var pointer_stop_distance: float = 8.0
@export var visual_scale: float = 0.82
@export var walk_atlas_columns: int = 4
@export var walk_atlas_rows: int = 9
@export var max_hp: int = 100
@export var attack: int = 12
@export var defense: int = 2
@export var attack_cooldown: float = 0.55
@export var attack_active_time: float = 0.12

enum AnimationState {
	IDLE,
	WALK,
}

var animation_state: AnimationState = AnimationState.IDLE
var facing_direction: Vector2 = Vector2.DOWN
var pointer_move_enabled: bool = false
var pointer_run_enabled: bool = false
var pointer_continuous_enabled: bool = false
var pointer_target: Vector2 = Vector2.ZERO

var _animation_time: float = 0.0
var _generated_sprite_base_position := Vector2.ZERO
var _attack_active_timer: float = 0.0
var _attack_cooldown_timer: float = 0.0

@onready var visual_root: Node2D = $VisualRoot
@onready var generated_sprite: Sprite2D = $VisualRoot/GeneratedSprite
@onready var health_component: Node = $HealthComponent
@onready var attack_hitbox: Area2D = $AttackHitbox
@onready var health_bar: Control = $HealthBar


func _ready() -> void:
	_generated_sprite_base_position = generated_sprite.position
	health_component.setup(max_hp, defense)
	attack_hitbox.setup(self, attack)
	_set_attack_hitbox_enabled(false)
	health_bar.bind(health_component)
	_apply_visual_facing()
	_update_generated_sprite_region()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT and mouse_event.pressed:
			start_pointer_move(get_global_mouse_position(), false, false)
		elif mouse_event.button_index == MOUSE_BUTTON_RIGHT and mouse_event.pressed:
			start_pointer_move(get_global_mouse_position(), true, false)
	elif _is_action_event(event, "attack_primary"):
		start_attack()
	elif _is_action_event(event, "interact"):
		interact_requested.emit()


func _physics_process(delta: float) -> void:
	_update_attack_timers(delta)
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
	if _attack_cooldown_timer > 0.0:
		return false

	_attack_active_timer = attack_active_time
	_attack_cooldown_timer = attack_cooldown
	_position_attack_hitbox()
	_set_attack_hitbox_enabled(true)
	return true


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

	if _attack_active_timer <= 0.0:
		return

	_attack_active_timer = maxf(0.0, _attack_active_timer - delta)
	if _attack_active_timer == 0.0:
		_set_attack_hitbox_enabled(false)


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
	var state_name := "idle" if animation_state == AnimationState.IDLE else "walk"
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


func _update_generated_sprite_region() -> void:
	if generated_sprite.texture == null:
		return

	var texture_size := generated_sprite.texture.get_size()
	var cell_size := Vector2(texture_size.x / float(walk_atlas_columns), texture_size.y / float(walk_atlas_rows))
	var direction_cell := get_direction_cell(facing_direction)
	var frame_index := 0
	if animation_state == AnimationState.WALK:
		frame_index = int(floor(_animation_time)) % walk_atlas_columns

	var row_index := get_test_atlas_row(direction_cell)
	generated_sprite.flip_h = should_flip_test_atlas_row(direction_cell)
	generated_sprite.position = _generated_sprite_base_position
	generated_sprite.region_rect = Rect2(Vector2(frame_index, row_index) * cell_size, cell_size)


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
