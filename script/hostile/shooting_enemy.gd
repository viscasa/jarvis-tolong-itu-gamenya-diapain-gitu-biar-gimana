extends EnemyBase


@export var projectile_scene: PackedScene

@export var reposition_distance: float = 100.0

@export var reposition_wander_range: float = 80.0

@export var reposition_speed_mult: float = 0.8


var _reposition_target_position: Vector2 = Vector2.ZERO



func _state_chase(delta):
	var distance_to_player = global_position.distance_to(player_target.global_position)
	var direction_to_player = global_position.direction_to(player_target.global_position)

	if distance_to_player > attack_range:
		velocity = direction_to_player * move_speed
		#animated_sprite.play("walk")
	
	elif distance_to_player < reposition_distance:
		velocity = -direction_to_player * move_speed 
		#animated_sprite.play("walk")
	
	else:
		velocity = Vector2.ZERO
		#animated_sprite.play("idle")

	if velocity.x != 0:
		animated_sprite.flip_h = (velocity.x > 0)



func _perform_attack():
	#animated_sprite.play("attack")
	
	# Hadapkan sprite ke player
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
	
	_reposition_target_position = Vector2.ZERO 
	_pick_new_reposition_target()


func _state_attack(delta):
	
	if global_position.distance_to(_reposition_target_position) < 10:
		_pick_new_reposition_target()

	var direction_to_target = global_position.direction_to(_reposition_target_position)
	velocity = direction_to_target * move_speed * reposition_speed_mult
	
	#animated_sprite.play("walk")
	if velocity.x != 0:
		animated_sprite.flip_h = (velocity.x < 0)


func _pick_new_reposition_target():
	var rand_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_reposition_target_position = global_position + rand_dir * reposition_wander_range


func _on_attack_timer_timeout():
	super._on_attack_timer_timeout()
	
	velocity = Vector2.ZERO
	_reposition_target_position = Vector2.ZERO
