extends CharacterBody2D
class_name Player
const SPEED = 150.0
const Y_MUL = 1.5
const ACCELERATION = 600.0

const DASH_SPEED = 600.0 
const EXIT_DASH_SPEED = 120.0

@onready var dash_manager: DashManager = $DashManager
@onready var possession_manager: PossessionManager = $PossessionManager

signal possessed(target)

var is_locked_out := false

func _ready() -> void:
	add_to_group("player")
	dash_manager.player = self
	possession_manager.player = self
	possession_manager.possessed.connect(_on_possessed)

func _physics_process(delta: float) -> void:
	
	dash_manager.update_cooldown(delta)

	if not is_locked_out:
		handle_global_inputs()

	if possession_manager.is_possessing:
		possession_manager.process_possession(delta)
	elif dash_manager.is_dash_moving:                     # was: is_dashing
		_set_dash_velocity()
	elif dash_manager.is_exit_moving:                     # was: is_exit_dashing
		_set_exit_dash_velocity()
	else:
		_process_movement(delta)

	move_and_slide()

	if dash_manager.is_dash_moving:
		dash_manager.process_dash(delta)
		if not dash_manager.is_dash_moving:               # BARU SAJA berakhir movement
			velocity *= 0.3
	elif dash_manager.is_exit_moving:
		dash_manager.process_exit_dash(delta)
		if not dash_manager.is_exit_moving:               # BARU SAJA berakhir movement
			velocity *= 0.3
	
func _set_dash_velocity():
	var speed_factor = dash_manager.get_dash_speed_factor()
	var current_dash_speed = DASH_SPEED * speed_factor
	velocity.x = dash_manager.dash_direction.x * current_dash_speed
	velocity.y = dash_manager.dash_direction.y * current_dash_speed / Y_MUL

func _set_exit_dash_velocity():
	var speed_factor = dash_manager.get_exit_dash_speed_factor()
	var base_exit_speed = dash_manager.current_exit_speed
	var current_speed = base_exit_speed * speed_factor
	velocity.x = dash_manager.exit_dash_direction.x * current_speed
	velocity.y = dash_manager.exit_dash_direction.y * current_speed / Y_MUL

func _process_movement(delta: float) -> void:
	var input_vector := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	var target_velocity = Vector2.ZERO
	if input_vector.length() > 0.0:
		target_velocity.x = input_vector.normalized().x * SPEED
		target_velocity.y = input_vector.normalized().y * SPEED / Y_MUL
	velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)

func can_start_possession() -> bool:
	if dash_manager.must_exit_before_possession and not dash_manager.has_exited_since_last_possession:
		print("⚠ You must Exit Dash before another possession.")
		return false
	return true

func handle_global_inputs() -> void:
	if Input.is_action_just_pressed("dash") and not possession_manager.is_possessing:
		if can_start_possession():
			dash_manager.start_dash()
	if Input.is_action_just_pressed("exit_dash") and possession_manager.is_possessing:
		dash_manager.start_exit_dash()

func _on_possessed(target):
	emit_signal("possessed", target)

func lock_actions_during_weak_exit(duration: float) -> void:
	if is_locked_out:
		return
	is_locked_out = true
	print("🔒 Locked out for %.2f seconds" % duration)
	await get_tree().create_timer(duration).timeout
	is_locked_out = false
	print("🔓 Lockout ended")
