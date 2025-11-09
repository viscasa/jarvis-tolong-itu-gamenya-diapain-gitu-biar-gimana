extends Node2D

signal morph_dash_ended
signal morph_dash_started

@export var dash_speed: float = 350
@export var dash_move_time: float = 0.15
@export var cooldown: float = 1
@export var wolf_dash_count: int = 2
@export var wolf_dash_delay: float = 0.7

@onready var player: Player = $"../.."
@onready var dash_manager: DashManager = $"../../DashManager"
@onready var super_dash: SuperDash = $"../SuperDash"
@onready var pin: Pin = $"../Pin"
@onready var homing_shot: HomingShot = $"../HomingShot"
@onready var triple_homing_shot: TripleHomingShot = $"../TripleHomingShot"
@onready var slash_shot: SlashShot = $"../SlashShot"

var is_dashing: bool = false
var is_in_delay: bool = false
var is_homing_shoot_ready:bool = false
var is_triple_homing_shoot_ready:bool = false
var is_slash_shot_ready: bool = false
var current_wolf_dashes: int = 0

var dash_move_timer: float = 0.0
var cooldown_timer: float = 0.0
var delay_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO # <-- ARAH DASH DISIMPAN DI SINI

func _process(delta: float) -> void:
	# ... (Tidak ada perubahan di _process)
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
		
	if is_in_delay:
		delay_timer -= delta
		if delay_timer <= 0.0:
			is_in_delay = false
			_start_dash_internal()
		return 
	
	if is_dashing:
		dash_move_timer -= delta
		if dash_move_timer <= 0.0:
			_end_dash_movement()

func is_active() -> bool:
	# ... (Tidak ada perubahan di is_active)
	return is_dashing

func _end_dash_movement() -> void:
	# ... (Tidak ada perubahan di _end_dash_movement)
	is_dashing = false
	
	if current_wolf_dashes > 0:
		current_wolf_dashes -= 1 
		
		process_all_skill(false) 
		
		if current_wolf_dashes > 0:
			is_in_delay = true
			delay_timer = wolf_dash_delay
			return
		else:
			process_all_skill(true) 
			emit_signal("morph_dash_ended")
			
	else:
		process_all_skill(true) 
		emit_signal("morph_dash_ended")

func process_all_skill(reset_flags: bool) -> void:
	# ... (Tidak ada perubahan di process_all_skill)
	if not reset_flags:
		if is_homing_shoot_ready :
			use_homing_shot()
		if is_triple_homing_shoot_ready :
			use_triple_homing_shot()
		if is_slash_shot_ready: 
			use_slash_shot()

	if reset_flags:
		is_homing_shoot_ready = false
		is_triple_homing_shoot_ready = false
		current_wolf_dashes = 0
		is_slash_shot_ready = false

func start_skill(homing_shoot_ready:bool = false, triple_homing_shoot_ready:bool = false, wolf_morph_ready:bool = false, slash_shot_ready: bool = false) -> bool:
	# ... (Tidak ada perubahan di start_skill)
	if is_dashing or is_in_delay or cooldown_timer > 0.0:
		return false
	
	if not homing_shoot_ready and not triple_homing_shoot_ready and not wolf_morph_ready and not slash_shot_ready:
		return false
	
	if not player or not dash_manager or not super_dash or not pin:
		return false
		
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active() or pin.is_active():
		return false

	is_homing_shoot_ready = homing_shoot_ready
	is_triple_homing_shoot_ready = triple_homing_shoot_ready
	is_slash_shot_ready = slash_shot_ready
	
	if wolf_morph_ready:
		current_wolf_dashes = wolf_dash_count 
	else:
		current_wolf_dashes = 1 
	
	_start_dash_internal() 
	return true

func _start_dash_internal():
	# ... (Tidak ada perubahan di _start_dash_internal)
	var input_vector := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	if input_vector.length_squared() > 0.1:
		dash_direction = input_vector.normalized()
	elif player.velocity.length_squared() > 10.0: 
		dash_direction = player.velocity.normalized()
	else:
		dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
		if dash_direction == Vector2.ZERO:
			dash_direction = Vector2.RIGHT 

	is_dashing = true
	dash_move_timer = dash_move_time
	
	if (wolf_dash_count > 0 and current_wolf_dashes == wolf_dash_count) or \
	   (wolf_dash_count == 0 and current_wolf_dashes == 1):
		cooldown_timer = cooldown
	
	emit_signal("morph_dash_started")

func get_dash_velocity() -> Vector2:
	# ... (Tidak ada perubahan di get_dash_velocity)
	if not is_dashing:
		return Vector2.ZERO
	return dash_direction * dash_speed

func use_homing_shot() -> void:
	# ... (Tidak ada perubahan di use_homing_shot)
	homing_shot.shoot_projectile()

func use_triple_homing_shot() -> void:
	# ... (Tidak ada perubahan di use_triple_homing_shot)
	triple_homing_shot.shoot_projectiles()

# --- PERUBAHAN DI SINI ---
func use_slash_shot() -> void:
	if slash_shot:
		# Berikan 'dash_direction' yang sudah tersimpan
		slash_shot.execute_shot(dash_direction)
# -------------------------
