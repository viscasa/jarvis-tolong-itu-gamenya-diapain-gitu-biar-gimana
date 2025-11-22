extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var body_radius: float = 10.0
@export var update_rate: float = 0.35
@export var knockback_strength: float = 200.0

enum State { CHASE, ATTACK, POSSESSED, DEAD, PLAYER_DEAD }

@onready var stats: Stats = $Stats
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_state: State = State.CHASE
var player_target: Node2D
var _time_since_update: float = 0.0
var is_in_knockback: bool = false
var last_move_direction: Vector2 = Vector2.DOWN
var is_attacking: bool = false
var is_stunned: bool = false
var _player_death_pending := false

func _ready() -> void:
	add_to_group("enemies")
	_init_ui()
	_init_timers()
	_init_nav()
	_find_player()
	connect_signals()
	hitbox_shape.disabled = true

func _init_ui():
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health

func _init_timers():
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true

func _init_nav():
	nav_agent.radius = body_radius
	nav_agent.simplify_path = true
	nav_agent.target_desired_distance = attack_range * 0.9
	nav_agent.path_desired_distance = 8.0
	call_deferred("_setup_navigation")

func _find_player():
	var players = get_tree().get_root().find_children("*", "Player", true, false)
	if not players.is_empty():
		player_target = players[0]
		if not player_target.is_connected("player_has_died", _on_player_death_detected):
			player_target.player_has_died.connect(_on_player_death_detected)
	if not is_instance_valid(player_target):
		current_state = State.DEAD
		set_physics_process(false)

func connect_signals():
	stats.no_health.connect(_on_death)
	stats.was_hit.connect(_on_was_hit)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	knockback_timer.timeout.connect(_on_knockback_timeout)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	animated_sprite.animation_finished.connect(_on_animation_finished)

func _setup_navigation():
	await get_tree().physics_frame
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if current_state == State.PLAYER_DEAD:
		_state_player_dead(delta)
		_update_animation_state()
		move_and_slide()
		return
	if not is_instance_valid(player_target) and current_state != State.POSSESSED:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	_time_since_update += delta
	if _time_since_update >= update_rate:
		_update_target_position()
		_time_since_update = 0.0
	var distance_to_player := global_position.distance_to(player_target.global_position)
	match current_state:
		State.CHASE:
			_state_chase(delta)
			var stopped := velocity.length_squared() < 1.0
			if stopped and distance_to_player <= attack_range and attack_timer.is_stopped():
				current_state = State.ATTACK
				_perform_attack()
				attack_timer.start()
		State.ATTACK:
			_state_attack(delta)
			if distance_to_player > attack_range * 1.2:
				current_state = State.CHASE
				_update_target_position()
		State.POSSESSED:
			_state_possessed(delta)
	_update_animation_state()
	move_and_slide()

func _update_target_position():
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _perform_attack():
	if is_instance_valid(player_target):
		last_move_direction = global_position.direction_to(player_target.global_position)
	is_attacking = true
	_update_animation_state()
	await get_tree().create_timer(0.5).timeout
	hitbox.damage = stats.get_final_damage()
	hitbox_shape.disabled = false
	await get_tree().create_timer(0.5).timeout
	if self and hitbox_shape:
		hitbox_shape.disabled = true

func _on_attack_timer_timeout():
	is_attacking = false 
	
	if _player_death_pending:
		current_state = State.PLAYER_DEAD
		return 
		
	current_state = State.CHASE
	_update_target_position()

func _on_death():
	current_state = State.DEAD
	
	PlayerBuffManager._on_enemy_killed()
	
	set_physics_process(false)
	var player := player_target
	if is_instance_valid(player):
		var buff_manager = player.get_node_or_null("BuffManager")
		if is_instance_valid(buff_manager):
			buff_manager._on_enemy_killed()
	queue_free()

func _on_was_hit(direction: Vector2):
	if current_state == State.ATTACK or is_in_knockback:
		return
	is_in_knockback = true
	nav_agent.avoidance_enabled = false
	velocity = direction * knockback_strength
	knockback_timer.start()

func _on_knockback_timeout():
	is_in_knockback = false
	nav_agent.avoidance_enabled = true

func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity

func _on_animation_finished():
	if is_stunned:
		is_stunned = false
	if is_attacking and _player_death_pending:
		is_attacking = false
		current_state = State.PLAYER_DEAD

func on_possessed():
	current_state = State.POSSESSED
	velocity = Vector2.ZERO
	is_stunned = true
	if is_instance_valid(player_target):
		last_move_direction = global_position.direction_to(player_target.global_position)

func on_released():
	current_state = State.CHASE
	_update_target_position()

func _state_chase(_delta: float) -> void:
	if is_in_knockback:
		return
	if not is_instance_valid(player_target):
		nav_agent.set_velocity(Vector2.ZERO)
		return
	var distance := global_position.distance_to(player_target.global_position)
	var target_velocity := Vector2.ZERO
	if distance > attack_range and not nav_agent.is_navigation_finished():
		var next_pos := nav_agent.get_next_path_position()
		var dir := (next_pos - global_position).normalized()
		target_velocity = dir * move_speed
	var requested := velocity.lerp(target_velocity, 8.0 * _delta)
	nav_agent.set_velocity(requested)

func _state_attack(_delta: float) -> void:
	if is_in_knockback:
		nav_agent.set_velocity(velocity.lerp(Vector2.ZERO, 5.0 * _delta))
		return
	nav_agent.set_velocity(velocity.lerp(Vector2.ZERO, 15.0 * _delta))

func _state_possessed(delta: float) -> void:
	is_stunned = true
	hitbox_shape.disabled = true
	if is_in_knockback:
		nav_agent.set_velocity(velocity.lerp(Vector2.ZERO, 5.0 * delta))
		return
	nav_agent.set_velocity(velocity.lerp(Vector2.ZERO, 15.0 * delta))

func _update_animation_state():
	var prefix := "IDLE"
	var dir := last_move_direction
	if current_state == State.PLAYER_DEAD:
		prefix = "IDLE"
	elif is_stunned:
		prefix = "STUNNED"
	elif is_attacking:
		prefix = "ATTACK"
	elif velocity.length() > 1.0:
		prefix = "WALK"
		dir = velocity.normalized()
		last_move_direction = dir
	_play_directional_animation(prefix, dir)

func _play_directional_animation(prefix: String, direction: Vector2):
	var suffix := _get_direction_suffix(direction)
	var anim := "%s_%s" % [prefix, suffix]
	if not animated_sprite.sprite_frames.has_animation(anim):
		anim = "%s_S" % prefix
		if not animated_sprite.sprite_frames.has_animation(anim):
			return
	if animated_sprite.animation != anim:
		animated_sprite.play(anim)

func _get_direction_suffix(direction: Vector2) -> String:
	var angle := direction.angle()
	if abs(angle) <= PI / 8.0: return "E"
	if angle <= 3.0 * PI / 8.0 and angle > PI / 8.0: return "SE"
	if angle <= 5.0 * PI / 8.0 and angle > 3.0 * PI / 8.0: return "S"
	if angle <= 7.0 * PI / 8.0 and angle > 5.0 * PI / 8.0: return "SW"
	if abs(angle) > 7.0 * PI / 8.0: return "W"
	if angle >= -7.0 * PI / 8.0 and angle < -5.0 * PI / 8.0: return "NW"
	if angle >= -5.0 * PI / 8.0 and angle < -3.0 * PI / 8.0: return "N"
	if angle >= -3.0 * PI / 8.0 and angle < -PI / 8.0: return "NE"
	return "S"

func _on_player_death_detected():
	_player_death_pending = true 
	attack_timer.stop() 
	
	if not is_attacking:
		current_state = State.PLAYER_DEAD

func _state_player_dead(_delta: float) -> void:
	nav_agent.set_velocity(Vector2.ZERO)
	velocity = Vector2.ZERO
