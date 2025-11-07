extends Node
class_name DashManager

var player: CharacterBody2D

# ========== Normal Dash ==========
const DASH_SPEED := 600.0
const DASH_TIME := 0.2
const COOLDOWN := 1.0

var is_dashing: bool = false
var dash_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

const EXIT_DASH_SPEED := 400.0
const EXIT_DASH_TIME := 0.2

var is_exit_dashing: bool = false
var is_exit_weak: bool = false
var exit_dash_timer: float = 0.0
var exit_dash_direction: Vector2 = Vector2.ZERO
var current_exit_speed: float = 0.0

const WEAK_EXIT_LOCK_TIME := 1.5
var weak_exit_lock_timer: float = 0.0

var must_exit_before_possession: bool = true
var has_exited_since_last_possession: bool = true

func update_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if weak_exit_lock_timer > 0.0:
		weak_exit_lock_timer -= delta


func can_dash() -> bool:
	return cooldown_timer <= 0.0 and weak_exit_lock_timer <= 0.0 and not is_dashing

func start_dash() -> void:
	if not can_dash():
		return

	if must_exit_before_possession and not has_exited_since_last_possession:
		print("⚠ Must exit before next possession dash!")
		return
		
	var mouse_pos = player.get_global_mouse_position()
	dash_direction = (mouse_pos - player.global_position).normalized()

	if is_exit_dashing and not is_exit_weak:
		print("Exit dash canceled by normal dash")
		force_end_exit_dash()

	is_dashing = true
	dash_timer = DASH_TIME
	
func on_possession_started() -> void:
	has_exited_since_last_possession = false

func process_dash(delta: float) -> void:
	if not is_dashing:
		return

	dash_timer -= delta
	
	if dash_timer <= 0.0:
		end_dash()

func get_dash_speed_factor() -> float:
	var progress := 1.0 - (dash_timer / DASH_TIME)
	progress = clamp(progress, 0.0, 1.0)
	
	var speed_factor := 1.0 - pow(1.0 - progress, 2.0) # Quadratic ease-out
	return speed_factor


func end_dash() -> void:
	is_dashing = false
	if not player.possession_manager.is_possessing:
		cooldown_timer = COOLDOWN

func start_exit_dash(weak: bool = false) -> void:
	is_exit_dashing = true
	is_exit_weak = weak
	exit_dash_timer = EXIT_DASH_TIME
	
	exit_dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()

	current_exit_speed = EXIT_DASH_SPEED
	if weak:
		current_exit_speed *= 0.5

	has_exited_since_last_possession = true


func process_exit_dash(delta: float) -> void:
	if not is_exit_dashing:
		return

	exit_dash_timer -= delta

	if exit_dash_timer <= 0.0:
		_end_exit_dash()


func _end_exit_dash() -> void:
	is_exit_dashing = false
	
	if is_exit_weak:
		weak_exit_lock_timer = WEAK_EXIT_LOCK_TIME
		player.lock_actions_during_weak_exit(WEAK_EXIT_LOCK_TIME)
		print("Weak exit lock: player restricted for %.2fs" % WEAK_EXIT_LOCK_TIME)
		
	is_exit_weak = false


func force_end_exit_dash() -> void:
	if is_exit_dashing:
		is_exit_dashing = false
		is_exit_weak = false
		exit_dash_timer = 0.0

func get_exit_dash_speed_factor() -> float:
	var progress := 1.0 - (exit_dash_timer / EXIT_DASH_TIME)
	progress = clamp(progress, 0.0, 1.0)
	var speed_factor := 1.0 - pow(1.0 - progress, 2.0)
	return speed_factor
