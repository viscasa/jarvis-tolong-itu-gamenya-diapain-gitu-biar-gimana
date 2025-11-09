extends Node2D
class_name TripleHomingShot

# Sinyal untuk Player
signal triple_shot_dash_started
signal triple_shot_dash_ended

# --- Scene Projectile ---
# GUNAKAN SCENE YANG SAMA DENGAN HOMING SHOT
@export var projectile_scene: PackedScene # Pasang HomingProjectile.tscn di sini

# --- Parameter Skill ---
@export var dash_speed: float = 350.0
@export var dash_move_time: float = 0.15 # Durasi dash
@export var cooldown: float = 0     # Cooldown skill
@export_range(0.1, 1.0) var spread_angle: float = 1 # Sudut sebar (seperti musuh)

@export_group("Projectile")
@export var missile_speed : float = 300.0
@export var missile_turn_rate : float = 10.0
@export var missile_damage : float = 15.0
@export var missile_lifetime : float = 3.0
@export var missile_proximity_threshold : float = 20.0

# --- Referensi (di-set oleh player._ready()) ---
var player: Player
var dash_manager: DashManager
var super_dash: SuperDash
var pin: Pin
var homing_shot: HomingShot # Referensi ke skill lain

# --- State ---
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

# Dipanggil oleh SkillManager
func start_skill() -> bool:
	# 1. Cek Cooldown & State
	if is_dashing or cooldown_timer > 0.0:
		return false
		
	# 2. Cek Skill Lain
	if not player or not dash_manager or not super_dash or not pin or not homing_shot:
		push_error("TripleHomingShot.gd: Referensi belum di-set oleh Player!")
		return false
		
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active() or pin.is_active() or homing_shot.is_active():
		return false
		
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
		return false

	# 4. Mulai Dash
	is_dashing = true
	dash_move_timer = dash_move_time
	cooldown_timer = cooldown # Mulai cooldown sekarang
	
	emit_signal("triple_shot_dash_started")
	return true
	
func _end_dash_movement() -> void:
	is_dashing = false
	emit_signal("triple_shot_dash_ended")
	_shoot_projectiles() # Ganti nama fungsi

func _shoot_projectiles() -> void: # Ganti nama fungsi
	if not projectile_scene:
		push_error("TripleHomingShot.gd: projectile_scene belum di-set!")
		return
			
	# 2. Tentukan arah awal (ke kursor, sebagai fallback jika tidak ada target)
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT
	
	# 3. Tembakkan 3 peluru
	_fire_one_projectile(initial_dir) # Lurus
	_fire_one_projectile(initial_dir.rotated(-spread_angle)) # Kiri
	_fire_one_projectile(initial_dir.rotated(spread_angle)) # Kanan

# Fungsi helper baru
func _fire_one_projectile(direction: Vector2):
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.damage = missile_damage
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	if proj.has_method("launch"):
		proj.launch(direction)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")

# Dipanggil oleh Player untuk set velocity
func get_dash_velocity() -> Vector2:
	if not is_dashing:
		return Vector2.ZERO
	# Player akan menerapkan Y_MUL
	return dash_direction * dash_speed
