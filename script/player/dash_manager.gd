extends Node
class_name DashManager

signal dash_movement_started
signal dash_movement_ended
signal dash_cycle_started
signal dash_cycle_ended

signal exit_movement_started
signal exit_movement_ended
signal exit_cycle_started
signal exit_cycle_ended

var player: CharacterBody2D

# ====== PARAM ======
const DASH_SPEED := 600.0
@export var dash_move_time := 0.20      # lamanya memberi velocity
@export var dash_cycle_time := 0.3     # lamanya 1 siklus dash (kamu atur)

const COOLDOWN := 1.0                   # cooldown dash dimulai saat CYCLE berakhir

const EXIT_DASH_SPEED := 600.0
@export var exit_move_time := 0.20
@export var exit_cycle_time := 0.4     # lamanya 1 siklus exit dash (kamu atur)

# ====== STATE (DASH) ======
var is_dashing: bool = false            # status CYCLE dash
var is_dash_moving: bool = false        # status pemberian velocity
var dash_move_timer: float = 0.0
var dash_cycle_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var _cooldown_set_for_cycle: bool = false

# ====== STATE (EXIT DASH) ======
var is_exit_dashing: bool = false       # status CYCLE exit dash
var is_exit_moving: bool = false        # status pemberian velocity
var exit_move_timer: float = 0.0
var exit_cycle_timer: float = 0.0
var is_exit_weak: bool = false
var exit_dash_direction: Vector2 = Vector2.ZERO
var current_exit_speed: float = 0.0

const WEAK_EXIT_LOCK_TIME := 1.5
var weak_exit_lock_timer: float = 0.0

var must_exit_before_possession: bool = true
var has_exited_since_last_possession: bool = true

# ====== TICK ======
func update_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if weak_exit_lock_timer > 0.0:
		weak_exit_lock_timer -= delta

	# hitung CYCLE dash
	if is_dashing:
		dash_cycle_timer -= delta
		if dash_cycle_timer <= 0.0:
			_end_dash_cycle()

	# hitung CYCLE exit dash
	if is_exit_dashing:
		exit_cycle_timer -= delta
		if exit_cycle_timer <= 0.0:
			_end_exit_cycle()

# ====== DASH ======
func can_dash() -> bool:
	return cooldown_timer <= 0.0 and weak_exit_lock_timer <= 0.0 and not is_dash_moving

func start_dash() -> void:
	if not can_dash():
		return
	if must_exit_before_possession and not has_exited_since_last_possession:
		print("⚠ Must exit before next possession dash!")
		return

	var mouse_pos = player.get_global_mouse_position()
	dash_direction = (mouse_pos - player.global_position).normalized()

	# Jika masih exit moving, hentikan gerak exit (cycle boleh lanjut)
	if is_exit_moving and not is_exit_weak:
		_force_end_exit_movement()

	# MULAI MOVEMENT
	is_dash_moving = true
	dash_move_timer = dash_move_time
	emit_signal("dash_movement_started")

	# MULAI CYCLE
	is_dashing = true
	dash_cycle_timer = dash_cycle_time
	_cooldown_set_for_cycle = false
	emit_signal("dash_cycle_started")

func process_dash(delta: float) -> void:
	if not is_dash_moving:
		return
	dash_move_timer -= delta
	if dash_move_timer <= 0.0:
		_end_dash_movement()

func _end_dash_movement() -> void:
	if not is_dash_moving:
		return
	is_dash_moving = false
	emit_signal("dash_movement_ended")

	# ⚠ cooldown TIDAK dipasang di sini; dipasang saat cycle berakhir

func _end_dash_cycle() -> void:
	if not is_dashing:
		return
	is_dashing = false
	emit_signal("dash_cycle_ended")
	# Cooldown mulai saat CYCLE berakhir
	if not _cooldown_set_for_cycle and not player.possession_manager.is_possessing:
		cooldown_timer = COOLDOWN
		_cooldown_set_for_cycle = true

func get_dash_speed_factor() -> float:
	if not is_dash_moving or dash_move_time <= 0.0:
		return 0.0
	var progress := 1.0 - (dash_move_timer / dash_move_time)
	progress = clamp(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - progress, 2.0) # ease-out

# ====== EXIT DASH ======
func start_exit_dash(weak: bool = false) -> void:
	is_exit_moving = true
	is_exit_dashing = true
	is_exit_weak = weak

	exit_move_timer = exit_move_time
	exit_cycle_timer = exit_cycle_time

	exit_dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	current_exit_speed = EXIT_DASH_SPEED * (0.5 if weak else 1.0)

	emit_signal("exit_movement_started")
	emit_signal("exit_cycle_started")

	has_exited_since_last_possession = true

func process_exit_dash(delta: float) -> void:
	if not is_exit_moving:
		return
	exit_move_timer -= delta
	if exit_move_timer <= 0.0:
		_end_exit_movement()
func _end_exit_movement() -> void:
	if not is_exit_moving:
		return
	is_exit_moving = false
	emit_signal("exit_movement_ended")
	if is_exit_weak:
		weak_exit_lock_timer = WEAK_EXIT_LOCK_TIME
		player.lock_actions_during_weak_exit(WEAK_EXIT_LOCK_TIME)
	is_exit_weak = false
	# ⚠ cooldown dash TIDAK dipasang oleh exit-dash (sesuai permintaan fokus ke dash)

func _end_exit_cycle() -> void:
	if not is_exit_dashing:
		return
	is_exit_dashing = false
	emit_signal("exit_cycle_ended")
	# tidak menyentuh cooldown

func _force_end_exit_movement() -> void:
	if is_exit_moving:
		is_exit_moving = false
		emit_signal("exit_movement_ended")

func force_end_exit_dash() -> void:
	_force_end_exit_movement()
	# jangan paksa akhiri cycle; biarkan _end_exit_cycle berjalan oleh timer

func get_exit_dash_speed_factor() -> float:
	if not is_exit_moving or exit_move_time <= 0.0:
		return 0.0
	var progress := 1.0 - (exit_move_timer / exit_move_time)
	progress = clamp(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - progress, 2.0)

func on_possession_started() -> void:
	# Kamu baru saja BERHASIL possess, jadi tandai bahwa
	# pemain BELUM melakukan exit lagi untuk possess berikutnya.
	has_exited_since_last_possession = false

	# Matikan semua status dash/exit agar state konsisten saat masuk possession.
	# (Baris yang tidak ada di versimu akan diabaikan oleh GDScript.)
	is_dashing = false
	is_exit_dashing = false

	# Jika kamu pakai var "moving" dan timer terpisah, reset juga:
	if "is_dash_moving" in self:
		is_dash_moving = false
	if "is_exit_moving" in self:
		is_exit_moving = false
	if "dash_move_timer" in self:
		dash_move_timer = 0.0
	if "exit_move_timer" in self:
		exit_move_timer = 0.0
	if "dash_cycle_timer" in self:
		dash_cycle_timer = 0.0
	if "exit_cycle_timer" in self:
		exit_cycle_timer = 0.0

	# Pastikan cooldown TIDAK dipasang karena cycle dipotong oleh possession.
	if " _cooldown_set_for_cycle" in self:
		_cooldown_set_for_cycle = true
