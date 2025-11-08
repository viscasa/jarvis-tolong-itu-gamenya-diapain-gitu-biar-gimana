extends EnemyBase

@export var reposition_distance: float = 30.0


#func _state_chase(delta):
	#var distance_to_player = global_position.distance_to(player_target.global_position)
	#var direction_to_player = global_position.direction_to(player_target.global_position)
#
	#
	#if distance_to_player > attack_range:
		#velocity = direction_to_player * move_speed
		##animated_sprite.play("walk")
		#
	#elif distance_to_player <= reposition_distance:
		#velocity = direction_to_player * Vector2(-1, -1) * move_speed 
		##animated_sprite.play("walk") 
	#
	#else:
		#velocity = Vector2.ZERO
		##animated_sprite.play("idle")
#
	#if velocity.x != 0:
		#animated_sprite.flip_h = (velocity.x > 0)
