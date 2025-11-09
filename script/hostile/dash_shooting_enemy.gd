extends EnemyBase

@export var projectile_scene: PackedScene

@export var reposition_distance: float = 60.0

@export_range(0.1, 1.0) var shotgun_spread_angle: float = 0.3 
@export var dash_speed: float = 350.0
@export var dash_duration: float = 0.25 

@onready var dash_check_left: RayCast2D = $DashCheckLeft
@onready var dash_check_right: RayCast2D = $DashCheckRight

enum AttackSubState { DASHING, RECOVERING }
var _attack_sub_state: AttackSubState = AttackSubState.RECOVERING
var _attack_state_timer: float = 0.0
var _dash_direction: Vector2 = Vector2.ZERO

func _ready():
	super._ready() 
	
	nav_agent.avoidance_enabled = false
	
	if nav_agent.is_connected("velocity_computed", _on_nav_agent_velocity_computed):
		nav_agent.disconnect("velocity_computed", _on_nav_agent_velocity_computed)


func _state_chase(delta):
	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
		return
		
	var distance_to_player = global_position.distance_to(player_target.global_position)
	var target_velocity: Vector2 = Vector2.ZERO 

	if distance_to_player > attack_range: 
		if nav_agent.is_navigation_finished(): 
			target_velocity = Vector2.ZERO 
		else:
			var next_position = nav_agent.get_next_path_position() 
			var direction = (next_position - global_position).normalized() 
			target_velocity = direction * move_speed 
			
	elif distance_to_player <= reposition_distance: 
		var direction_to_player = (player_target.global_position - global_position).normalized() 
		target_velocity = -direction_to_player * move_speed

	else:
		target_velocity = Vector2.ZERO 

	velocity = velocity.lerp(target_velocity, 8.0 * delta) 
	
	if target_velocity == Vector2.ZERO and velocity.length_squared() < 25.0: 
		velocity = Vector2.ZERO
	
	if velocity.x != 0: 
		animated_sprite.flip_h = (velocity.x < 0)


func _perform_attack():
	#animated_sprite.play("attack")
	if not is_instance_valid(player_target): return
	var dir_to_player = global_position.direction_to(player_target.global_position)
	
	if dir_to_player.x != 0: 
		animated_sprite.flip_h = (dir_to_player.x < 0) 
	
	if projectile_scene: 
		_fire_projectile(dir_to_player) 
		_fire_projectile(dir_to_player.rotated(-shotgun_spread_angle)) 
		_fire_projectile(dir_to_player.rotated(shotgun_spread_angle)) 
	else:
		print("ERROR: Projectile Scene belum di-set di " + name) 
	
	_pick_dash_direction(dir_to_player) 
	_attack_sub_state = AttackSubState.DASHING 
	_attack_state_timer = dash_duration 

func _fire_projectile(direction: Vector2): 
	var proj = projectile_scene.instantiate() 
	get_parent().add_child(proj) 
	proj.global_position = global_position 
	proj.direction = direction 
	proj.damage = stats.get_final_damage() 

func _state_attack(delta): 
	var target_velocity: Vector2
	
	match _attack_sub_state: 
		
		AttackSubState.DASHING: 
			target_velocity = _dash_direction * dash_speed
			velocity = target_velocity 
			
			_attack_state_timer -= delta 
			if _attack_state_timer <= 0: 
				_attack_sub_state = AttackSubState.RECOVERING 

		AttackSubState.RECOVERING: 
			target_velocity = Vector2.ZERO
			velocity = velocity.lerp(target_velocity, 15.0 * delta) 


func _pick_dash_direction(dir_to_player: Vector2): 
	var dir_left = dir_to_player.rotated(-PI / 2.0) 
	var dir_right = dir_to_player.rotated(PI / 2.0) 
	
	dash_check_left.rotation = dir_left.angle() 
	dash_check_right.rotation = dir_right.angle() 
	
	dash_check_left.force_raycast_update() 
	dash_check_right.force_raycast_update() 
	
	var can_dash_left = not dash_check_left.is_colliding() 
	var can_dash_right = not dash_check_right.is_colliding() 
	
	_dash_direction = Vector2.ZERO 
	
	if can_dash_left and can_dash_right: 
		_dash_direction = dir_left if randf() > 0.5 else dir_right 
	elif can_dash_left: 
		_dash_direction = dir_left 
	elif can_dash_right: 
		_dash_direction = dir_right 

func _on_attack_timer_timeout(): 
	super._on_attack_timer_timeout() 
	velocity = Vector2.ZERO 
	_attack_sub_state = AttackSubState.RECOVERING
