extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5 

@onready var stats: Stats = $Stats
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var nav_agent: NavigationAgent2D = $NavAgent
@export var body_radius := 10
@export var update_rate := 0.35
enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 
var player_target: Node2D = null 
var _time_since_update := 0.0

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
	if current_state == State.DEAD or current_state == State.POSSESSED:
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if not is_instance_valid(player_target):
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
			
	move_and_slide()

func _update_target_position():
	if is_instance_valid(player_target):
		var distance_to_target = player_target.global_position.distance_to(nav_agent.target_position)
		
		nav_agent.target_position = player_target.global_position



func _state_chase(delta):
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
	
	if requested_velocity.x != 0:
		animated_sprite.flip_h = (requested_velocity.x < 0)
		
func _state_attack(delta):
	var requested_velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
	nav_agent.set_velocity(requested_velocity)
	
	if is_instance_valid(player_target):
		var direction_to_player = sign(player_target.global_position.x - global_position.x)
		if direction_to_player != 0:
			animated_sprite.flip_h = direction_to_player < 0

func connect_signals():
	stats.no_health.connect(_on_death)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)
func on_possessed():
	current_state = State.POSSESSED
	velocity = Vector2.ZERO

func on_released():
	current_state = State.CHASE
	_update_target_position()

func _perform_attack():
	hitbox.damage = stats.get_final_damage()
	hitbox_shape.disabled = false
	
	await get_tree().create_timer(0.2).timeout
	
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
	queue_free()

func _on_attack_timer_timeout() -> void:
	current_state = State.CHASE
	_update_target_position()


func _on_nav_agent_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
