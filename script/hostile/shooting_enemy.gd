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

@onready var bullet_spawn_points := {
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
	var distance := global_position.distance_to(player_target.global_position)
	var target_velocity := Vector2.ZERO
	if distance > attack_range and not nav_agent.is_navigation_finished():
		var next := nav_agent.get_next_path_position()
		var dir := (next - global_position).normalized()
		target_velocity = dir * move_speed
	elif distance <= reposition_distance:
		var dir_player := (player_target.global_position - global_position).normalized()
		target_velocity = -dir_player * move_speed
	var requested := velocity.lerp(target_velocity, 8.0 * delta)
	nav_agent.set_velocity(requested)

func _perform_attack():
	if not is_instance_valid(player_target):
		return
	var dir := global_position.direction_to(player_target.global_position)
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT
	last_move_direction = dir
	is_attacking = true
	var suffix := _get_direction_suffix(dir)
	var marker: Marker2D = bullet_spawn_points.get(suffix, self)
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = marker.global_position
		proj.direction = dir
		proj.damage = stats.get_final_damage()
	_attack_sub_state = AttackSubState.RELOADING
	_attack_state_timer = reload_time

func _state_attack(delta):
	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		return
	var target_velocity := Vector2.ZERO
	match _attack_sub_state:
		AttackSubState.RELOADING:
			_attack_state_timer -= delta
			if _attack_state_timer <= 0.0:
				_attack_sub_state = AttackSubState.WANDERING
				_pick_new_wander_target()
		AttackSubState.WANDERING:
			var dir := global_position.direction_to(_wander_target_pos)
			target_velocity = dir * move_speed * wander_speed_mult
			if global_position.distance_to(_wander_target_pos) < 10.0:
				_pick_new_wander_target()
	var requested := velocity.lerp(target_velocity, 8.0 * delta)
	nav_agent.set_velocity(requested)

func _pick_new_wander_target():
	var rand_dir := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_wander_target_pos = global_position + rand_dir * wander_range

func _on_attack_timer_timeout():
	super._on_attack_timer_timeout()
	_attack_sub_state = AttackSubState.RELOADING

func _physics_process(delta):
	if is_attacking:
		velocity = Vector2.ZERO
	super._physics_process(delta)
