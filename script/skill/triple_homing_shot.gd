extends Node2D
class_name TripleHomingShot

# Sinyal untuk Player
signal triple_shot_dash_started
signal triple_shot_dash_ended

# --- Scene Projectile ---
# GUNAKAN SCENE YANG SAMA DENGAN HOMING SHOT
@export var projectile_scene: PackedScene # Pasang HomingProjectile.tscn di sini

@export_group("Projectile")
@export var missile_speed : float = 300.0
@export var missile_turn_rate : float = 10.0
@export var missile_damage : float = 15.0
@export var missile_lifetime : float = 3.0
@export var missile_proximity_threshold : float = 20.0
@export_range(0.1, 1.0) var spread_angle: float = 1 # Sudut sebar (seperti musuh)

@onready var player: Player = $"../.."

func shoot_projectiles() -> void: # Ganti nama fungsi
	if not projectile_scene:
		push_error("TripleHomingShot.gd: projectile_scene belum di-set!")
		return
			
	# 2. Tentukan arah awal (ke kursor, sebagai fallback jika tidak ada target)
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT
	
	# 3. Tembakkan 3 peluru
	_fire_one_projectile(initial_dir) # Lurus
	_fire_one_projectile(initial_dir.rotated(-spread_angle)) # Kiri
	_fire_one_projectile(initial_dir.rotated(spread_angle)) # Kanan

# Fungsi helper baru
func _fire_one_projectile(direction: Vector2):
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.damage = missile_damage
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	if proj.has_method("launch"):
		proj.launch(direction)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")
