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
		
	# 1. Cari musuh terdekat
	
	# 2. Buat projectile
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	var stats = buff_manager.current_stats

	proj.damage = missile_damage * stats.borrowed_damage
	
	# Terapkan "Chain Shot" & "Spectral Spike"
	proj.chain_count = stats.homing_chain
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	# 3. Tentukan arah awal (ke kursor, sebagai fallback jika tidak ada target)
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT
	
	# 4. Luncurkan
	if proj.has_method("launch"):
		proj.launch(initial_dir)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")
