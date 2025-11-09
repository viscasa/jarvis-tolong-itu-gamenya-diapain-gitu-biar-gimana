extends CharacterBody2D
class_name Player

const SPEED = 150.0
const Y_MUL = 1.5
const ACCELERATION = 600.0

const DASH_SPEED = 600.0 
const EXIT_DASH_SPEED = 120.0

@onready var dash_manager: DashManager = $DashManager
@onready var possession_manager: PossessionManager = $PossessionManager
@onready var skill_manager: Node2D = $SkillManager

# Referensi skill di dalam SkillManager
@onready var super_dash: SuperDash = $SkillManager/SuperDash
@onready var pin: Pin = $SkillManager/Pin
@onready var morph_skill: Node2D = $SkillManager/MorphSkill
@onready var homing_shot: HomingShot = $SkillManager/HomingShot
@onready var triple_homing_shot: TripleHomingShot = $SkillManager/TripleHomingShot

signal possessed(target)

var is_locked_out := false

func _ready() -> void:
	add_to_group("player")
	
	# Setup referensi DashManager
	dash_manager.player = self
	
	# Setup referensi PossessionManager
	possession_manager.player = self
	possession_manager.possessed.connect(_on_possessed)

	# --- PENGATURAN REFERENSI SKILL ---
	# Beri referensi ke SuperDash
	super_dash.player = self
	super_dash.dash_manager = dash_manager
	
	# Beri referensi ke Pin
	pin.player = self
	pin.dash_manager = dash_manager
	pin.super_dash = super_dash
	
	# Beri referensi skill ke DashManager
	dash_manager.super_dash = super_dash
	dash_manager.pin = pin


func _physics_process(delta: float) -> void:
	
	dash_manager.update_cooldown(delta)
	
	# Proses semua skill
	super_dash.process_super_dash(delta)
	pin._process(delta) 
	morph_skill._process(delta) 

	if not is_locked_out:
		handle_global_inputs()

	# --- PENGATURAN VELOCITY ---
	if possession_manager.is_possessing:
		possession_manager.process_possession(delta)
	elif super_dash.is_charging:
		_set_super_dash_charge_velocity()
	elif super_dash.is_dashing:
		_set_super_dash_move_velocity()
	elif dash_manager.is_dash_moving:
		_set_dash_velocity()
	elif dash_manager.is_exit_moving:
		_set_exit_dash_velocity()
	elif morph_skill.is_dashing:
		_set_morph_dash_velocity()
	else:
		_process_movement(delta)
	# --- AKHIR PENGATURAN VELOCITY ---

	move_and_slide()

	# Proses logika akhir dash
	if dash_manager.is_dash_moving:
		dash_manager.process_dash(delta)
		if not dash_manager.is_dash_moving:
			velocity *= 0.3
	elif dash_manager.is_exit_moving:
		dash_manager.process_exit_dash(delta)
		if not dash_manager.is_exit_moving:
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

func _set_super_dash_charge_velocity():
	var vel = super_dash.get_charge_velocity()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL

func _set_super_dash_move_velocity():
	var vel = super_dash.get_dash_velocity()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL

func _set_morph_dash_velocity():
	var vel = morph_skill.get_dash_velocity()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL

func _process_movement(delta: float) -> void:
	# Pastikan kita tidak bergerak jika ada skill dash aktif
	if super_dash.is_active() or morph_skill.is_active(): # TAMBAHAN
		velocity = Vector2.ZERO
		return

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
	if Input.is_action_just_pressed("super_dash") and not possession_manager.is_possessing:
		if can_start_possession():
			skill_manager.start_or_return_super_dash()
	
	elif Input.is_action_just_pressed("dash") and not possession_manager.is_possessing:
		if can_start_possession():
			dash_manager.start_dash()
	
	elif Input.is_action_just_pressed("pin") and not possession_manager.is_possessing:
		if can_start_possession():
			skill_manager.use_pin()
	elif Input.is_action_just_pressed("morph_skill") and not possession_manager.is_possessing: # TAMBAHAN
		if can_start_possession():
			skill_manager.use_morph_skill()

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

func morph(name:String) :
	skill_manager.morph(name)
