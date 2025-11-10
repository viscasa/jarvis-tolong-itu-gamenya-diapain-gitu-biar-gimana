extends Node2D
class_name SlashShot

# Scene untuk projectile tebasan (SlashProjectile.tscn)
@export var projectile_scene: PackedScene

# Parameter bisa di-set di sini atau di projectile_scene
@export_group("Projectile")
@export var slash_damage: float = 25.0
@export var slash_speed: float = 600.0
@export var slash_lifetime: float = 0.25 # Dibuat singkat agar seperti tebasan

@onready var player: Player = $"../.."

# --- PERUBAHAN DI SINI ---
# Fungsi ini sekarang menerima 'direction' dari morph_skill.gd
func execute_shot(direction: Vector2) -> void:
# -------------------------
	if not projectile_scene:
		push_error("SlashShot.gd: projectile_scene belum di-set!")
		return
		
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj) # Tambahkan ke root
	proj.global_position = player.global_position
	
	# Set parameter tebasan
	proj.damage = slash_damage
	proj.speed = slash_speed
	proj.lifetime = slash_lifetime
	
	# --- PERUBAHAN DI SINI ---
	# Gunakan 'direction' dari parameter, bukan dari mouse
	var initial_dir = direction
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT # Fallback jika arah dash 0
	# -------------------------
	
	# Luncurkan
	if proj.has_method("launch"):
		proj.launch(initial_dir)
	else:
		push_error("Scene SlashProjectile.tscn tidak punya method launch()!")
