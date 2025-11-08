extends EnemyBase	

@export var reposition_distance: float = 30.0

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
	
	if velocity.x != 0:
		animated_sprite.flip_h = (velocity.x < 0)
