extends Node2D

signal morph_dash_ended
signal morph_dash_started

@export var dash_speed: float = 350
@export var dash_move_time: float = 0.15
@export var cooldown: float = 5

@onready var player: Player = $"../.."
@onready var dash_manager: DashManager = $"../../DashManager"
@onready var super_dash: SuperDash = $"../SuperDash"
@onready var pin: Pin = $"../Pin"
@onready var homing_shot: HomingShot = $"../HomingShot"
@onready var triple_homing_shot: TripleHomingShot = $"../TripleHomingShot"

var is_dashing: bool = false
var is_homing_shoot_ready:bool = false
var is_triple_homing_shoot_ready:bool = false
var dash_move_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	if is_dashing:
		dash_move_timer -= delta
		if dash_move_timer <= 0.0:
			_end_dash_movement()

func is_active() -> bool:
	return is_dashing

func _end_dash_movement() -> void:
	is_dashing = false
	if is_homing_shoot_ready :
		use_homing_shot()
	if is_triple_homing_shoot_ready :
		use_triple_homing_shot()
	emit_signal("morph_dash_ended")

func start_skill(homing_shoot_ready:bool = false, triple_homing_shoot_ready:bool = false) -> bool:
	# 1. Cek Cooldown & State
	if is_dashing or cooldown_timer > 0.0:
		return false
	
	if !homing_shoot_ready and !triple_homing_shoot_ready :
		return false
	
	# 2. Cek Skill Lain
	if not player or not dash_manager or not super_dash or not pin: # TAMBAHAN
		return false
		
	# --- MODIFIKASI: Cek semua skill ---
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active() or pin.is_active(): # TAMBAHAN
		return false
	# --- AKHIR MODIFIKASI ---
		
	# 3. Tentukan Arah Dash (berdasarkan input/gerakan player)
	var input_vector := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if input_vector.length_squared() > 0.1:
		dash_direction = input_vector.normalized()
	elif player.velocity.length_squared() > 10.0: # Fallback ke velocity
		dash_direction = player.velocity.normalized()
	else:
		return false # Tidak bergerak, tidak bisa dash

	# 4. Mulai Dash
	is_dashing = true
	is_triple_homing_shoot_ready = triple_homing_shoot_ready
	is_homing_shoot_ready = homing_shoot_ready
	dash_move_timer = dash_move_time
	cooldown_timer = cooldown
	
	emit_signal("morph_dash_started")
	return true

# Dipanggil oleh Player untuk set velocity
func get_dash_velocity() -> Vector2:
	if not is_dashing:
		return Vector2.ZERO
	# Player akan menerapkan Y_MUL
	return dash_direction * dash_speed

func use_homing_shot() -> void:
	homing_shot.shoot_projectile()
	is_homing_shoot_ready = false

func use_triple_homing_shot() -> void:
	triple_homing_shot.shoot_projectiles()
	is_triple_homing_shoot_ready
