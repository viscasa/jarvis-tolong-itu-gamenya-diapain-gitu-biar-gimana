extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5 
@export var show_debug_path: bool = true

@onready var stats: Stats = $Stats
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer
@onready var health_bar: ProgressBar = $HealthBar
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var debug_path_line: Line2D = $DebugPathLine

enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 
var player_target: Node2D = null 

# Path update throttling
var path_update_timer: float = 0.0

func _ready():
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	connect_signals()
	hitbox_shape.disabled = true
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	
	nav_agent.simplify_path = true
	
	
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
	
	path_update_timer += delta

	_update_target_position()
	
	if show_debug_path:
		_draw_debug_path()
	
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	match current_state:
		State.CHASE:
			_state_chase(delta) 
			
			if distance_to_player <= attack_range and attack_timer.is_stopped():
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
		if distance_to_target > 20.0 or not nav_agent.is_target_reachable():
			nav_agent.target_position = player_target.global_position

func _draw_debug_path():
	if not is_instance_valid(debug_path_line):
		return
		
	if not nav_agent.is_target_reachable():
		debug_path_line.default_color = Color.ORANGE
		debug_path_line.points = PackedVector2Array()
		return
		
	debug_path_line.default_color = Color.RED
	
	var path_points: PackedVector2Array = nav_agent.get_current_navigation_path()
	var local_points: PackedVector2Array = []
	
	for point in path_points:
		local_points.append(to_local(point))
	
	debug_path_line.points = local_points

func _state_chase(delta):
	var distance_to_player = global_position.distance_to(player_target.global_position)

	if distance_to_player <= attack_range:
		velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta) 
		return
	
	if nav_agent.is_navigation_finished():
		if distance_to_player > attack_range * 1.5:
			_update_target_position()
		velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
		return
	
	var direct_to_player = global_position.direction_to(player_target.global_position)
	if distance_to_player < 150.0:  
		var space_state = get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(global_position, player_target.global_position)
		query.exclude = [self]
		query.collision_mask = 1  
		
		var result = space_state.intersect_ray(query)
		if not result:  
			velocity = direct_to_player * move_speed
			if abs(direct_to_player.x) > 0.1:
				animated_sprite.flip_h = direct_to_player.x < 0
			return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = global_position.direction_to(next_position)
	
	var blend_factor = clamp(distance_to_player / 200.0, 0.0, 1.0)
	direction = direction.lerp(direct_to_player, 1.0 - blend_factor)
	direction = direction.normalized()
	
	var target_velocity = direction * move_speed
	velocity = velocity.lerp(target_velocity, 8.0 * delta)
	
	if abs(direction.x) > 0.1:
		animated_sprite.flip_h = direction.x < 0

func _state_attack(delta):
	velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
	
	if is_instance_valid(player_target):
		var direction_to_player = sign(player_target.global_position.x - global_position.x)
		if direction_to_player != 0:
			animated_sprite.flip_h = direction_to_player < 0

func connect_signals():
	stats.no_health.connect(_on_death)
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	
func on_possessed():
	current_state = State.POSSESSED
	velocity = Vector2.ZERO

func on_released():
	current_state = State.CHASE
	path_update_timer = 0.0
	_update_target_position()

func _perform_attack():
	hitbox.damage = stats.get_final_damage()
	hitbox_shape.disabled = false
	
	await get_tree().create_timer(0.2).timeout
	
	if self and hitbox_shape:
		hitbox_shape.disabled = true
		
func _on_death():
	print(name + " mati!")
	current_state = State.DEAD
	
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	if $Hurtbox: 
		$Hurtbox/CollisionShape2D.disabled = true
	
	await animated_sprite.animation_finished
	queue_free()

func _on_attack_timer_timeout() -> void:
	current_state = State.CHASE
	_update_target_position()
