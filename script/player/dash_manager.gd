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

signal exit_dash_manual_started
signal auto_exit_dash_started

var player: CharacterBody2D
var super_dash: SuperDash
var pin: Pin 
@onready var morph_skill: Node2D = $"../SkillManager/MorphSkill"
@onready var sprite: AnimatedSprite2D = $"../Sprite"
@onready var ghost_timer: Timer = $"../GhostTimer"
@onready var possession_manager: PossessionManager = $"../PossessionManager"
@onready var possess_area: Area2D = $"../PossessArea"
var ghost_scene = preload("res://scene/skill/dash_ghost.tscn")

const SCALE_UP = 1.7
const DASH_SPEED := 600.0 * SCALE_UP
@export var dash_move_time := 0.20
@export var dash_cycle_time := 0.3

const COOLDOWN := 1.0

const EXIT_DASH_SPEED := 600.0 * SCALE_UP
@export var exit_move_time := 0.20
@export var exit_cycle_time := 0.3

var is_dashing: bool = false
var is_dash_moving: bool = false
var dash_move_timer: float = 0.0
var dash_cycle_timer: float = 0.0
var cooldown_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var _cooldown_set_for_cycle: bool = false

var is_exit_dashing: bool = false
var is_exit_moving: bool = false
var exit_move_timer: float = 0.0
var exit_cycle_timer: float = 0.0
var is_exit_weak: bool = false
var exit_dash_direction: Vector2 = Vector2.ZERO
var current_exit_speed: float = 0.0
const WEAK_EXIT_LOCK_TIME := 1.5
var weak_exit_lock_timer: float = 0.0
var must_exit_before_possession: bool = true
var has_exited_since_last_possession: bool = true
var auto_exit_possess_lock: bool = false
var dash_count_max: int = 1
var dash_counter : int = 0

var _is_phasing_dash: bool = false


func update_cooldown(delta: float) -> void:
	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	if weak_exit_lock_timer > 0.0:
		weak_exit_lock_timer -= delta
	if is_dashing:
		dash_cycle_timer -= delta
		if dash_cycle_timer <= 0.0:
			_end_dash_cycle()
	if is_exit_dashing:
		exit_cycle_timer -= delta
		if exit_cycle_timer <= 0.0:
			_end_exit_cycle()
			auto_exit_possess_lock = false

func can_dash() -> bool:
	if (super_dash and super_dash.is_active()) or \
	   (pin and pin.is_active()) or \
	   (morph_skill and morph_skill.is_active()): 
		return false
	
	if (cooldown_timer <= 0.0 and weak_exit_lock_timer <= 0.0 and not is_dash_moving):
		dash_counter = 0
	if dash_counter<dash_count_max :
		return true
	else :
		return false

func start_dash() -> void:
	if is_dashing or is_dash_moving:
		return
	if not can_dash():
		return
	if must_exit_before_possession and not has_exited_since_last_possession:
		return

	var mouse_pos = player.get_global_mouse_position()
	dash_direction = (mouse_pos - player.global_position).normalized()

	if is_exit_moving and not is_exit_weak:
		_force_end_exit_movement()
	
	player.raycast.rotation = dash_direction.angle()
	
	player.phasing_ray.force_raycast_update()
	
	var can_phase = not player.phasing_ray.is_colliding()
	
	
	dash_counter += 1
	is_dash_moving = true
	dash_move_timer = dash_move_time
	emit_signal("dash_movement_started")
	is_dashing = true
	dash_cycle_timer = dash_cycle_time
	_cooldown_set_for_cycle = false
	emit_signal("dash_cycle_started")
	AudioManager.start_sfx(self, "res://assets/audio/dash.wav", [2, 3], 0, 0.1)
	var _areas = possess_area.get_overlapping_areas()
	for _area in _areas:
		if _area is Hurtbox:
			_area.reset_hurtbox()
			break
	
	if auto_exit_possess_lock:
		player.end_invisible()
	elif can_phase:
		_is_phasing_dash = true
		player.start_invisible()
		ghost_timer.wait_time = 0.07
		ghost_timer.start()
	else:
		_is_phasing_dash = false
		ghost_timer.wait_time = 0.07
		ghost_timer.start()

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

func _end_dash_cycle() -> void:
	if not is_dashing:
		return
	is_dashing = false
	emit_signal("dash_cycle_ended")
	if not _cooldown_set_for_cycle and not player.possession_manager.is_possessing:
		cooldown_timer = COOLDOWN
		_cooldown_set_for_cycle = true
	
	if _is_phasing_dash:
		player.end_invisible()
	_is_phasing_dash = false 
	
	
	ghost_timer.stop()

func get_dash_speed_factor() -> float:
	if not is_dash_moving or dash_move_time <= 0.0:
		return 0.0
	var progress := 1.0 - (dash_move_timer / dash_move_time)
	progress = clamp(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - progress, 2.0)

func start_exit_dash(weak: bool = false, is_auto: bool = false) -> void:
	if (super_dash and super_dash.is_active()) or \
	   (pin and pin.is_active()) or \
	   (morph_skill and morph_skill.is_active()):
		return
		
	is_exit_moving = true
	is_exit_dashing = true
	is_exit_weak = weak
	exit_move_timer = exit_move_time
	exit_cycle_timer = exit_cycle_time
	exit_dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	current_exit_speed = EXIT_DASH_SPEED * (0.5 if weak else 1.0)
	
	var mouse_pos = player.get_global_mouse_position()
	dash_direction = (mouse_pos - player.global_position).normalized()

	player.end_invisible()
	
	AudioManager.start_sfx(self, "res://assets/audio/go out.wav", [0.9, 1.1], 0)
	if is_auto:
		auto_exit_possess_lock = true
		emit_signal("auto_exit_dash_started")
		is_dashing = true
	else:
		emit_signal("exit_dash_manual_started")
		AudioManager.start_sfx(self, "res://assets/audio/dash.wav", [2, 3], 0, 0.1)
		player.immune_damage(true)
		_is_phasing_dash = false
		ghost_timer.wait_time = 0.07
		ghost_timer.start()
		var _areas = possess_area.get_overlapping_areas()
		for _area in _areas:
			if _area is Hurtbox:
				_area.reset_hurtbox()
				break

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

func _end_exit_cycle() -> void:
	if not is_exit_dashing:
		return
	is_exit_dashing = false
	emit_signal("exit_cycle_ended")
	
	player.end_invisible()
	_is_phasing_dash = false 
	
	if is_dashing: return
	ghost_timer.stop()

func _force_end_exit_movement() -> void:
	if is_exit_moving:
		is_exit_moving = false
		emit_signal("exit_movement_ended")

func force_end_exit_dash() -> void:
	_force_end_exit_movement()

func get_exit_dash_speed_factor() -> float:
	if not is_exit_moving or exit_move_time <= 0.0:
		return 0.0
	var progress := 1.0 - (exit_move_timer / exit_move_time)
	progress = clamp(progress, 0.0, 1.0)
	return 1.0 - pow(1.0 - progress, 2.0)

func on_possession_started() -> void:
	ghost_timer.stop()
	has_exited_since_last_possession = false
	is_dashing = false
	is_exit_dashing = false
	is_dash_moving = false
	is_exit_moving = false
	dash_move_timer = 0.0
	exit_move_timer = 0.0
	dash_cycle_timer = 0.0
	exit_cycle_timer = 0.0
	_cooldown_set_for_cycle = true
	
	if _is_phasing_dash:
		player.end_invisible()
		_is_phasing_dash = false

func instance_ghost() -> void :
	var ghost: Sprite2D = ghost_scene.instantiate()
	get_parent().get_parent().add_child(ghost)
	
	ghost.global_position = self.global_position
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func _on_ghost_timer_timeout() -> void:
	instance_ghost()
