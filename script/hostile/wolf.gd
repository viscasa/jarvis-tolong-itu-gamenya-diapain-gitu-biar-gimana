extends EnemyBase

@export var dash_speed: float = 400.0
@export var charge_time: float = 0.5   
@export var dash_duration: float = 0.3 

enum WolfAttackState { CHARGING, DASHING, DASHBACK, RECOVERING }
var wolf_attack_state: WolfAttackState = WolfAttackState.RECOVERING

var charge_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

func _ready():
	super._ready() 
	
	nav_agent.avoidance_enabled = false
	
	if nav_agent.is_connected("velocity_computed", _on_nav_agent_velocity_computed):
		nav_agent.disconnect("velocity_computed", _on_nav_agent_velocity_computed)


func _state_chase(delta):
	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
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
	
	velocity = velocity.lerp(target_velocity, 8.0 * delta)
	
	if target_velocity == Vector2.ZERO and velocity.length_squared() < 25.0: 
		velocity = Vector2.ZERO
	
	if velocity.x != 0:
		animated_sprite.flip_h = (velocity.x < 0)

func _perform_attack():
	if wolf_attack_state != WolfAttackState.RECOVERING:
		return

	wolf_attack_state = WolfAttackState.CHARGING
	charge_timer = charge_time
	#animated_sprite.play("charge") 
	
	if is_instance_valid(player_target):
		dash_direction = global_position.direction_to(player_target.global_position)
	else:
		dash_direction = Vector2.RIGHT 
	
	if dash_direction.x != 0:
		animated_sprite.flip_h = (dash_direction.x < 0)

func _state_attack(delta):
	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	var target_velocity: Vector2

	match wolf_attack_state:
		
		WolfAttackState.CHARGING:
			target_velocity = Vector2.ZERO
			velocity = velocity.lerp(target_velocity, 15.0 * delta)
			
			charge_timer -= delta
			if charge_timer <= 0:
				wolf_attack_state = WolfAttackState.DASHING
				dash_timer = dash_duration
				hitbox.damage = stats.get_final_damage() 
				hitbox_shape.disabled = false
		
		WolfAttackState.DASHING:
			target_velocity = dash_direction * dash_speed
			velocity = target_velocity 
			
			dash_timer -= delta
			if dash_timer <= 0:
				dash_timer = dash_duration
				wolf_attack_state = WolfAttackState.DASHBACK
				if self and hitbox_shape:
					hitbox_shape.disabled = true
					
		WolfAttackState.DASHBACK:
			print("dashback")
			target_velocity = -dash_direction * dash_speed
			velocity = target_velocity 
			dash_timer -= delta
			if dash_timer <= 0:
				wolf_attack_state = WolfAttackState.RECOVERING
				if self and hitbox_shape:
					hitbox_shape.disabled = true
		WolfAttackState.RECOVERING:
			target_velocity = Vector2.ZERO
			velocity = velocity.lerp(target_velocity, 15.0 * delta) 
			

func _on_attack_timer_timeout():
	super._on_attack_timer_timeout()
	
	wolf_attack_state = WolfAttackState.RECOVERING
	
	if self and hitbox_shape:
		hitbox_shape.disabled = true
