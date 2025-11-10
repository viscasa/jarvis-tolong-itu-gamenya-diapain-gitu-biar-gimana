extends CharacterBody2D
class_name Player

const SCALE_UP = 1.7
const SPEED = 150.0 * SCALE_UP
const Y_MUL = 2
const Y_MUL_DASH = 1.7
const ACCELERATION = 600.0 * SCALE_UP

const DASH_SPEED = 600.0  * SCALE_UP
const EXIT_DASH_SPEED = 120.0 * SCALE_UP

@onready var dash_manager: DashManager = $DashManager
@onready var possession_manager: PossessionManager = $PossessionManager
@onready var skill_manager: Node2D = $SkillManager

# Referensi skill di dalam SkillManager
@onready var super_dash: SuperDash = $SkillManager/SuperDash
@onready var pin: Pin = $SkillManager/Pin
@onready var morph_skill: Node2D = $SkillManager/MorphSkill
@onready var homing_shot: HomingShot = $SkillManager/HomingShot
@onready var triple_homing_shot: TripleHomingShot = $SkillManager/TripleHomingShot
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var possess_area: Area2D = $PossessArea
@onready var hurt_box_player: HurtboxPlayer = $HurtBoxPlayer

signal possessed(target)

var is_locked_out := false

# --- VAR ANIMASI BARU ---
# Menyimpan arah terakhir pemain (dari input atau dash) untuk animasi idle
var last_move_direction := Vector2.DOWN


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

	# --- LOGIKA ANIMASI BARU ---
	# Panggil state machine animasi sebelum bergerak
	_update_animation_state()
	# --- AKHIR LOGIKA ANIMASI ---

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
	velocity.y = dash_manager.dash_direction.y * current_dash_speed / Y_MUL_DASH
	last_move_direction = dash_manager.dash_direction # Update arah terakhir

func _set_exit_dash_velocity():
	var speed_factor = dash_manager.get_exit_dash_speed_factor()
	var base_exit_speed = dash_manager.current_exit_speed
	var current_speed = base_exit_speed * speed_factor
	velocity.x = dash_manager.exit_dash_direction.x * current_speed
	velocity.y = dash_manager.exit_dash_direction.y * current_speed / Y_MUL_DASH
	last_move_direction = dash_manager.exit_dash_direction # Update arah terakhir

func _set_super_dash_charge_velocity():
	var vel = super_dash.get_charge_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized() # Update arah terakhir
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _set_super_dash_move_velocity():
	var vel = super_dash.get_dash_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized() # Update arah terakhir
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _set_morph_dash_velocity():
	var vel = morph_skill.get_dash_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized() # Update arah terakhir
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _process_movement(delta: float) -> void:
	# Pastikan kita tidak bergerak jika ada skill dash aktif
	if super_dash.is_active() or morph_skill.is_active(): # TAMBAHAN
		velocity = Vector2.ZERO
		return

	var input_vector := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	
	# Update arah terakhir berdasarkan input
	if input_vector.length() > 0.0:
		last_move_direction = input_vector.normalized()
	
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

func start_invisible(time:float = 0) :
	print("invis!")
	hurt_box_player.get_node("CollisionShape2D").disabled = true
	hurt_box_player.set_collision_layer_value(2, false)
	if time != 0 :
		await get_tree().create_timer(time).timeout
		end_invisible()

func end_invisible() :
	print("berhenti invis!")
	hurt_box_player.get_node("CollisionShape2D").disabled = false
	hurt_box_player.set_collision_layer_value(2, true)

# ==================================================================
# --- FUNGSI ANIMASI BARU ---
# ==================================================================

# "Otak" dari state machine animasi.
# Menentukan prefix animasi (idle, walk, dash) dan arahnya.
func _update_animation_state() -> void:
	var anim_prefix = "Idle" # <- PERBAIKAN BUG: "Idle" menjadi "idle"
	var anim_direction = last_move_direction # Default untuk idle

	# Prioritas 1: Sedang Possessing?
	if possession_manager.is_possessing:
		# ASUMSI: Saat possessing, player pakai animasi "morph".
		# Ganti "morph_walk"/"morph_idle" dengan "walk"/"idle" biasa
		# jika Anda tidak punya animasi morph khusus.
		if velocity.length() > 1.0:
			anim_prefix = "Idle" # cth: "morph_walk_n" <- PERBAIKAN BUG: "Idle" menjadi "idle" (atau "morph_walk")
			anim_direction = velocity.normalized()
		else:
			anim_prefix = "Idle" # cth: "morph_idle_n" <- PERBAIKAN BUG: "Idle" menjadi "idle" (atau "morph_idle")
			anim_direction = last_move_direction
	
	# Prioritas 2: Sedang Dash atau Charge?
	elif super_dash.is_charging:
		anim_prefix = "Idle" # cth: "charge_n" <- PERBAIKAN BUG: "Idle" menjadi "charge"
		var charge_vel = super_dash.get_charge_velocity()
		if charge_vel.length_squared() > 0.0:
			anim_direction = charge_vel.normalized()
		else:
			anim_direction = last_move_direction
	
	elif super_dash.is_dashing or morph_skill.is_dashing or dash_manager.is_dash_moving or dash_manager.is_exit_moving:
		anim_prefix = "Idle" # cth: "dash_n" <- PERBAIKAN BUG: "Idle" menjadi "dash"
		# Ambil arah dash yang relevan
		if super_dash.is_dashing:
			anim_direction = super_dash.get_dash_velocity().normalized()
		elif morph_skill.is_dashing:
			anim_direction = morph_skill.get_dash_velocity().normalized()
		elif dash_manager.is_dash_moving:
			anim_direction = dash_manager.dash_direction
		else: # exit_moving
			anim_direction = dash_manager.exit_dash_direction
	
	# Prioritas 3: Sedang Bergerak (Walk)?
	elif velocity.length() > 1.0: # Bergerak normal (di luar dash/skill)
		anim_prefix = "Idle" # <- PERBAIKAN BUG: "Idle" menjadi "walk"
		anim_direction = velocity.normalized() # Arah dari velocity aktual
	
	# Prioritas 4: Idle
	# Jika tidak ada di atas, prefix = "idle" dan direction = "last_move_direction"

	if anim_direction.length_squared() > 0:
		possess_area.rotation = anim_direction.angle()
	# ---------------------

	_play_directional_animation(anim_prefix, anim_direction)


# Memutar animasi berdasarkan prefix (cth: "idle") dan arah (Vector2).
func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	# Dapatkan akhiran 8 arah (n, ne, e, se, s, sw, w, nw)
	var suffix := _get_direction_suffix(direction)
	var anim_name = "%s_%s" % [prefix, suffix]
	
	# Hanya putar animasi jika berbeda dengan yang sekarang
	# Ini mencegah animasi di-reset setiap frame
	if sprite.animation != anim_name:
		sprite.play(anim_name)


# Mengubah Vector2 menjadi salah satu dari 8 akhiran arah.
func _get_direction_suffix(direction: Vector2) -> String:
	# Arah 0 radian di Godot adalah KANAN (1, 0)
	# PI/2 adalah BAWAH (0, 1)
	# -PI/2 adalah ATAS (0, -1)
	var angle = direction.angle()
	
	# Cek 8 irisan lingkaran (masing-masing PI/4 atau 45 derajat)
	# Kita geser sedikit (PI/8) agar "e" (kanan) ada di tengah irisan 0
	
	if abs(angle) <= PI / 8.0:
		return "E"
	elif angle > PI / 8.0 and angle <= 3.0 * PI / 8.0:
		return "SE"
	elif angle > 3.0 * PI / 8.0 and angle <= 5.0 * PI / 8.0:
		return "S"
	elif angle > 5.0 * PI / 8.0 and angle <= 7.0 * PI / 8.0:
		return "SW"
	elif abs(angle) > 7.0 * PI / 8.0:
		return "W"
	elif angle < -5.0 * PI / 8.0 and angle >= -7.0 * PI / 8.0:
		return "NW"
	elif angle < -3.0 * PI / 8.0 and angle >= -5.0 * PI / 8.0:
		return "N"
	elif angle < -PI / 8.0 and angle >= -3.0 * PI / 8.0:
		return "NE"
	
	return "S" # Fallback default
