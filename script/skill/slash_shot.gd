extends Node2D
class_name SlashShot

@export var projectile_scene: PackedScene

@export_group("Projectile")
@export var slash_damage: float = 25.0
@export var slash_speed: float = 600.0
@export var slash_lifetime: float = 0.25 

@onready var player: Player = $"../.."

func execute_shot(direction: Vector2) -> void:
	if not projectile_scene:
		push_error("SlashShot.gd: projectile_scene belum di-set!")
		return
	
	var stats = PlayerBuffManager.current_stats
	

	
	var proj = projectile_scene.instantiate()
	get_tree().root.add_child(proj)
	proj.global_position = player.global_position
	
	proj.damage = slash_damage * stats.borrowed_damage 
	
	proj.scale *= stats.slash_aoe 
	
	proj.speed = slash_speed
	proj.lifetime = slash_lifetime
	
	var initial_dir = direction
	if initial_dir == Vector2.ZERO:
		initial_dir = Vector2.RIGHT 
	
	if proj.has_method("launch"):
		proj.launch(direction) 
	else:
		push_error("Scene SlashProjectile.tscn tidak punya method launch()!")
