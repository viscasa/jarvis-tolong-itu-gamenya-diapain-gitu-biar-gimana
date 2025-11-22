extends Node2D
class_name HomingShot

signal homing_shot_dash_started
signal homing_shot_dash_ended

@onready var player: Player = $"../.."

@export var projectile_scene: PackedScene

@export_group("Projectile")
@export var missile_speed : float = 300.0
@export var missile_turn_rate : float = 10.0
@export var missile_damage : float = 15.0
@export var missile_lifetime : float = 3.0
@export var missile_proximity_threshold : float = 20.0

func shoot_projectile() -> void:
	if not projectile_scene:
		push_error("HomingShot.gd: projectile_scene belum di-set!")
		return
		
	var stats = PlayerBuffManager.current_stats

	var bullet_count = stats.bullet_multiplier
	
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT

	# IMPROVEMENT: Tambahkan delay untuk bullet ke-2 dst
	for i in range(bullet_count):
		if i > 0:
			await get_tree().create_timer(0.1).timeout
			
		var fire_dir = initial_dir.rotated(randf_range(-0.1, 0.1) * i)
		_fire_one_projectile(fire_dir, stats)
		
func _fire_one_projectile(direction: Vector2, stats: PlayerModifier):
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)  
	proj.global_position = player.global_position
	
	proj.damage = missile_damage * stats.borrowed_damage
	proj.chain_count = stats.homing_chain
	
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	if proj.has_method("launch"):
		proj.launch(direction)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")
