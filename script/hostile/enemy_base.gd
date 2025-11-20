extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5 

@onready var stats: Stats = $Stats
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var knockback_timer: Timer = $KnockbackTimer
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var body_radius := 10
@export var update_rate := 0.35
enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 
var player_target: Node2D = null 
var _time_since_update := 0.0
var is_in_knockback: bool = false
@export var knockback_strength: float = 200.0
var last_move_direction := Vector2.DOWN # Arah default
var is_attacking: bool = false
var is_stunned: bool = false
func _ready():
	add_to_group("enemies")
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	connect_signals()
	hitbox_shape.disabled = true
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	
	nav_agent.radius = body_radius
	nav_agent.simplify_path = true
	nav_agent.target_desired_distance = attack_range * 0.9 
	nav_agent.path_desired_distance = 8.0
	call_deferred("_setup_navigation")
	
	var player_nodes = get_tree().get_root().find_children("*", "Player", true, false)
	
	if not player_nodes.is_empty():
		player_target = player_nodes[0]
	
	if not is_instance_valid(player_target):
		print("PERINGATAN: Enemy " + name + " tidak bisa menemukan 'player' di scene!")
		current_state = State.DEAD 
		set_physics_process(false)

func _setup_navigation():
	await get_tree().physics_frame
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _physics_process(delta):
	if current_state == State.DEAD:
		velocity = Vector2.ZERO
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

	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	match current_state:
		State.CHASE:
			_state_chase(delta) 
			var is_stopped = velocity.length_squared() < 1.0
			
			if distance_to_player <= attack_range and attack_timer.is_stopped() and is_stopped:
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
		var distance_to_target = player_target.global_position.distance_to(nav_agent.target_position)
		
		nav_agent.target_position = player_target.global_position



func _state_chase(delta):
	if is_in_knockback:
		var requested_velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	if not is_instance_valid(player_target):
		nav_agent.set_velocity(Vector2.ZERO) 
		return
		
	var distance_to_player = global_position.distance_to(player_target.global_position)
	var target_velocity = Vector2.ZERO 

	if distance_to_player <= attack_range:
		target_velocity = Vector2.ZERO
	
	elif nav_agent.is_navigation_finished():
		target_velocity = Vector2.ZERO
	else:
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		target_velocity = direction * move_speed
	
	var requested_velocity = velocity.lerp(target_velocity, 8.0 * delta)
	
	nav_agent.set_velocity(requested_velocity)
	

		
func _state_attack(delta):
	if is_in_knockback:
		var requested_velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	var requested_velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
	nav_agent.set_velocity(requested_velocity)
	


func connect_signals():
	stats.no_health.connect(_on_death)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
	stats.was_hit.connect(_on_was_hit)
	knockback_timer.timeout.connect(_on_knockback_timeout)
	animated_sprite.animation_finished.connect(_on_animation_finished)
func on_possessed():
	current_state = State.POSSESSED
	velocity = Vector2.ZERO
	is_stunned = true
	
	if is_instance_valid(player_target):
		last_move_direction = global_position.direction_to(player_target.global_position)
func on_released():
	current_state = State.CHASE
	_update_target_position()

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
		
func _on_death():
	current_state = State.DEAD
	
	set_physics_process(false)
	#$CollisionShape2D.disabled = true
	#if $Hurtbox: 
		#$Hurtbox/CollisionShape2D.disabled = true
	#
	#await animated_sprite.animation_finished
	var player = player_target #
	if is_instance_valid(player):
		var buff_manager = player.get_node_or_null("BuffManager")
		if is_instance_valid(buff_manager):
			buff_manager._on_enemy_killed()
	queue_free()

func _on_attack_timer_timeout() -> void:
	current_state = State.CHASE
	_update_target_position()


func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	
	
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
	
func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false # Reset flag
	if is_stunned:
		is_stunned = false
# "Otak" animasi
func _update_animation_state() -> void:
	var anim_prefix = "IDLE" # Default
	var anim_direction = last_move_direction # Default

	if is_stunned:
		anim_prefix = "STUNNED"
	elif is_attacking:
		anim_prefix = "ATTACK"
		# (Gunakan 'last_move_direction' yang sudah di-set di _perform_attack)
		
	# Prioritas 2: Sedang Bergerak (Walk)?
	elif velocity.length() > 1.0: 
		anim_prefix = "WALK" # (Ganti dari "Run" ke "WALK" sesuai nama Anda)
		anim_direction = velocity.normalized()
		last_move_direction = anim_direction # Simpan arah gerak terakhir
	
	# Prioritas 3: Idle
	# (Jika tidak ada di atas, prefix = "IDLE" dan direction = "last_move_direction")

	_play_directional_animation(anim_prefix, anim_direction)


# Memutar animasi berdasarkan prefix (cth: "IDLE") dan arah (Vector2).
func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	var suffix := _get_direction_suffix(direction)
	var anim_name = "%s_%s" % [prefix, suffix]
	# Cek keamanan jika animasi tidak ada
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		# Fallback ke arah Selatan (S)
		anim_name = "%s_S" % prefix
		if not animated_sprite.sprite_frames.has_animation(anim_name):
			print("ERROR: Animasi %s_S tidak ditemukan!" % prefix)
			return
	
	if animated_sprite.animation != anim_name:
		animated_sprite.play(anim_name)


# Mengubah Vector2 menjadi salah satu dari 8 akhiran arah (N, NE, E, SE, S, SW, W, NW)
func _get_direction_suffix(direction: Vector2) -> String:
	var angle = direction.angle()
	
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
	
func _state_possessed(delta):
	is_stunned = true
	hitbox_shape.disabled = true
	if is_in_knockback:
		var requested_velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		nav_agent.set_velocity(requested_velocity)
		return
	var requested_velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
	nav_agent.set_velocity(requested_velocity)
