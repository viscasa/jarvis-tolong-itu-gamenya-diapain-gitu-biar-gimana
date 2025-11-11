extends Node2D
class_name HomingShot

signal homing_shot_dash_started
signal homing_shot_dash_ended

@onready var player: Player = $"../.."

@export var projectile_scene: PackedScene
@onready var buff_manager: PlayerBuffManager = $"../../BuffManager" # Sesuaikan path

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
		
	var stats = buff_manager.current_stats

	var bullet_count = stats.bullet_multiplier
	
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT

	# Tembakkan 'bullet_count' kali
	for i in range(bullet_count):
		# Beri sedikit sebaran acak agar tidak menumpuk
		var fire_dir = initial_dir.rotated(randf_range(-0.1, 0.1) * i)
		_fire_one_projectile(fire_dir, stats)
		
func _fire_one_projectile(direction: Vector2, stats: PlayerModifier):
	print("shot")
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	
	# Terapkan boon
	print(missile_damage)
	proj.damage = missile_damage * stats.borrowed_damage
	proj.chain_count = stats.homing_chain
	
	# Set stat proyektil
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	# 4. Luncurkan
	if proj.has_method("launch"):
		proj.launch(direction)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")
