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
@onready var buff_manager: PlayerBuffManager = $"../../BuffManager" # Sesuaikan path
@export_range(0.1, 1.0) var spread_angle: float = 1 # Sudut sebar (seperti musuh)

@onready var player: Player = $"../.."

func shoot_projectiles() -> void:
	if not projectile_scene:
		push_error("TripleHomingShot.gd: projectile_scene belum di-set!")
		return
	
	# --- DAPATKAN STAT TERBARU ---
	var stats = buff_manager.current_stats
	
	var initial_dir = (player.get_global_mouse_position() - player.global_position).normalized()
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT
	
	# Tembakkan 3 peluru (dasar)
	_fire_one_projectile(initial_dir, stats) # Lurus
	_fire_one_projectile(initial_dir.rotated(-spread_angle), stats) # Kiri
	_fire_one_projectile(initial_dir.rotated(spread_angle), stats) # Kanan
	
	# Dapatkan jumlah peluru dari boon
	var bullet_multiplier = stats.bullet_multiplier
	
	# Loop berdasarkan 'bullet_multiplier'
	for i in range(bullet_multiplier):
		# Beri sedikit offset acak untuk 'echo'
		var offset_angle = 0.1 * i
		
		_fire_one_projectile(initial_dir.rotated(offset_angle), stats) # Lurus
		_fire_one_projectile(initial_dir.rotated(-spread_angle + offset_angle), stats) # Kiri
		_fire_one_projectile(initial_dir.rotated(spread_angle + offset_angle), stats) # Kanan

# --- PERBAIKAN: Fungsi ini perlu 'stats' ---
func _fire_one_projectile(direction: Vector2, stats: PlayerModifier):
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = player.global_position
	
	# --- TERAPKAN BOON ---
	# Terapkan "Grandma's Revenge" & "House of Sticks"
	proj.damage = missile_damage * stats.borrowed_damage
	
	# Terapkan "Chain Shot" & "Spectral Spike"
	proj.chain_count = stats.homing_chain
	# --------------------
	
	proj.speed = missile_speed
	proj.turn_rate = missile_turn_rate
	proj.lifetime = missile_lifetime
	proj.proximity_threshold = missile_proximity_threshold
	
	if proj.has_method("launch"):
		proj.launch(direction)
	else:
		push_error("Scene HomingProjectile.tscn tidak punya method launch()!")
