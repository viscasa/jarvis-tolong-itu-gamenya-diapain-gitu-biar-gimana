extends EnemyBase

@export var projectile_scene: PackedScene

@export var reposition_distance: float = 100.0 
@export var reposition_speed_mult: float = 0.7 

@export var reload_time: float = 0.5 
@export_range(0.0, 1.0) var orbit_strength: float = 0.8 

enum AttackSubState { RELOADING, REPOSITIONING }
var _attack_sub_state: AttackSubState = AttackSubState.RELOADING
var _attack_state_timer: float = 0.0
var _strafe_dir: int = 1 



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



func _perform_attack():
	
	var direction_to_player = global_position.direction_to(player_target.global_position)
	if direction_to_player.x != 0:
		animated_sprite.flip_h = (direction_to_player.x < 0)
	
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj) 
		proj.global_position = global_position
		proj.direction = direction_to_player
		proj.damage = stats.get_final_damage()
	else:
		print("ERROR: Projectile Scene belum di-set di " + name)
	
	_attack_sub_state = AttackSubState.RELOADING
	_attack_state_timer = reload_time
	
	_strafe_dir = 1 if randf() > 0.5 else -1


func _state_attack(delta):
	
	match _attack_sub_state:
		
		AttackSubState.RELOADING:
			velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
			
			_attack_state_timer -= delta
			if _attack_state_timer <= 0:
				_attack_sub_state = AttackSubState.REPOSITIONING

		AttackSubState.REPOSITIONING:
			if not is_instance_valid(player_target):
				velocity = Vector2.ZERO
				return

			var dist_to_player = global_position.distance_to(player_target.global_position)
			var dir_to_player = (player_target.global_position - global_position).normalized()

			var orbit_dir = dir_to_player.rotated(PI / 2.0 * _strafe_dir)

			var ideal_dist = (attack_range + reposition_distance) / 2.0
			var correction_dir = Vector2.ZERO
			
			if dist_to_player > ideal_dist:
				correction_dir = dir_to_player
			elif dist_to_player < ideal_dist:
				correction_dir = -dir_to_player
				
			var final_dir = correction_dir.lerp(orbit_dir, orbit_strength).normalized()

			var target_velocity = final_dir * move_speed * reposition_speed_mult
			velocity = velocity.lerp(target_velocity, 5.0 * delta) 
			
			#animated_sprite.play("walk")
			if velocity.x != 0:
				animated_sprite.flip_h = (velocity.x < 0)


func _on_attack_timer_timeout():
	super._on_attack_timer_timeout()
	
	velocity = Vector2.ZERO
	_attack_sub_state = AttackSubState.RELOADING
