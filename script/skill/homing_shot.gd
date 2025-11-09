extends Node2D
class_name HomingShot

signal homing_shot_dash_started
signal homing_shot_dash_ended

@export var projectile_scene: PackedScene

@export var dash_speed: float = 350
@export var dash_move_time: float = 0.15
@export var cooldown: float = 0

@export_group("Projectile")
@export var missile_speed : float = 300.0
@export var missile_turn_rate : float = 10.0
@export var missile_damage : float = 15.0
@export var missile_lifetime : float = 3.0
@export var missile_proximity_threshold : float = 20.0

var player: Player
var dash_manager: DashManager
var super_dash: SuperDash
var pin: Pin
var triple_homing_shot: TripleHomingShot # TAMBAHAN

var is_dashing: bool = false
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

func start_skill() -> bool:
	# 1. Cek Cooldown & State
	if is_dashing or cooldown_timer > 0.0:
		return false
		
	# 2. Cek Skill Lain
	if not player or not dash_manager or not super_dash or not pin or not triple_homing_shot: # TAMBAHAN
		return false
		
	# --- MODIFIKASI: Cek semua skill ---
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active() or pin.is_active() or triple_homing_shot.is_active(): # TAMBAHAN
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
	dash_move_timer = dash_move_time
	cooldown_timer = cooldown
	
	emit_signal("homing_shot_dash_started")
	return true

func _end_dash_movement() -> void:
	is_dashing = false
	emit_signal("homing_shot_dash_ended")
	_shoot_projectile()

func _shoot_projectile() -> void:
	if not projectile_scene:
		push_error("HomingShot.gd: projectile_scene belum di-set!")
		return
		
	# 1. Cari musuh terdekat
	
	# 2. Buat projectile
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.damage = missile_damage
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	# 3. Tentukan arah awal (ke kursor, sebagai fallback jika tidak ada target)
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT
	
	# 4. Luncurkan
	if proj.has_method("launch"):
		proj.launch(initial_dir)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")

# Dipanggil oleh Player untuk set velocity
func get_dash_velocity() -> Vector2:
	if not is_dashing:
		return Vector2.ZERO
	# Player akan menerapkan Y_MUL
	return dash_direction * dash_speed
