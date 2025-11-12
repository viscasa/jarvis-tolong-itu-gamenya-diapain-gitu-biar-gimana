extends EnemyBase

@export var projectile_scene: PackedScene

@export var reposition_distance: float = 80.0 
@export var reload_time: float = 0.5 
@export var wander_range: float = 60.0 
@export var wander_speed_mult: float = 0.6 
enum AttackSubState { RELOADING, WANDERING }
var _attack_sub_state: AttackSubState = AttackSubState.RELOADING
var _attack_state_timer: float = 0.0
var _wander_target_pos: Vector2 = Vector2.ZERO
@onready var west: Marker2D = $BulletPosition/West
@onready var south_west: Marker2D = $BulletPosition/SouthWest
@onready var east: Marker2D = $BulletPosition/East
@onready var south_east: Marker2D = $BulletPosition/SouthEast
@onready var north_east: Marker2D = $BulletPosition/NorthEast
@onready var north_west: Marker2D = $BulletPosition/NorthWest
@onready var south: Marker2D = $BulletPosition/South
@onready var north: Marker2D = $BulletPosition/North
@onready var bullet_spawn_points: Dictionary = {
	"N": $BulletPosition/North,
	"NE": $BulletPosition/NorthEast,
	"E": $BulletPosition/East,
	"SE": $BulletPosition/SouthEast,
	"S": $BulletPosition/South,
	"SW": $BulletPosition/SouthWest,
	"W": $BulletPosition/West,
	"NW": $BulletPosition/NorthWest
}

func _state_chase(delta):
	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	if not is_instance_valid(player_target):
		nav_agent.set_velocity(Vector2.ZERO) 
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

	var requested_velocity = velocity.lerp(target_velocity, 8.0 * delta)
	
	nav_agent.set_velocity(requested_velocity)
	


func _perform_attack():
	if not is_instance_valid(player_target): return
	var dir_to_player:Vector2 = global_position.direction_to(player_target.global_position)
	if dir_to_player == Vector2.ZERO :
		dir_to_player = Vector2.RIGHT
	
	last_move_direction = dir_to_player
	is_attacking = true

	var direction_suffix = _get_direction_suffix(dir_to_player)
	var spawn_marker = bullet_spawn_points.get(direction_suffix)
	#await animated_sprite.animation_finished	
	if not is_instance_valid(spawn_marker):
		print("ERROR: Marker %s tidak ditemukan!" % direction_suffix)
		spawn_marker = self # Fallback: spawn di tengah musuh
	
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = spawn_marker.global_position # Gunakan posisi Marker
		proj.direction = dir_to_player
		proj.damage = stats.get_final_damage()
	else:
		print("ERROR: Projectile Scene belum di-set di " + name)
	
	_attack_sub_state = AttackSubState.RELOADING
	_attack_state_timer = reload_time

func _state_attack(delta):

	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	var target_velocity: Vector2 = Vector2.ZERO

	match _attack_sub_state:
		
		AttackSubState.RELOADING:
			target_velocity = Vector2.ZERO 
			_attack_state_timer -= delta
			
			if _attack_state_timer <= 0:
				_attack_sub_state = AttackSubState.WANDERING
				_pick_new_wander_target()

		AttackSubState.WANDERING:
			#animated_sprite.play("walk")
			var direction = global_position.direction_to(_wander_target_pos)
			target_velocity = direction * move_speed * wander_speed_mult
			
			if global_position.distance_to(_wander_target_pos) < 10:
				_pick_new_wander_target()

	var requested_velocity = velocity.lerp(target_velocity, 8.0 * delta)
	nav_agent.set_velocity(requested_velocity)


func _pick_new_wander_target():
	var rand_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_wander_target_pos = global_position + rand_dir * wander_range


func _on_attack_timer_timeout():
	super._on_attack_timer_timeout() 
	_attack_sub_state = AttackSubState.RELOADING

func _physics_process(delta):
	if is_attacking:
		velocity = Vector2.ZERO
	super._physics_process(delta)
		
