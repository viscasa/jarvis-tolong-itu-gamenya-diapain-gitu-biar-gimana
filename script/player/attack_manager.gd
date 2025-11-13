extends Node2D
class_name AttackManager

signal critical_circle


var crit_multiplier:float = 2.0
var enemy_stats:Stats = null


func attack(enemy:Node, hit_direction: Vector2,  is_critical: bool, damage:float = -1.0) -> void :
	var enemy_stats
	if enemy is Scissor :
		return
	if enemy is CharacterBody2D :
		enemy_stats = enemy.get_node("Stats")
	else :
		enemy_stats= enemy.get_owner().get_node("Stats")
	if !enemy_stats :
		return

	# --- PERBAIKAN LOGIKA DAMAGE ---
	var final_damage = damage
	if final_damage == -1.0:
		# Jika 'damage' tidak disediakan (misal dari 'circle_timing'), hitung di sini
		final_damage = get_final_damage(is_critical) 
	
	# Cek Frenzy (Hunter's Haste)
	# -----------------------------

	if is_critical :
		enemy_stats.take_damage(final_damage, hit_direction, crit_multiplier)
		emit_signal("critical_circle")
	else :
		enemy_stats.take_damage(final_damage, hit_direction)
func get_final_damage(is_critical: bool = false) -> float:
	# Dapatkan stat terbaru dari 'otak'
	var stats = PlayerBuffManager.current_stats
	
	var calculated_damage = stats.base_damage # Ini adalah base damage (default 20.0)
	
	if is_critical:
		# Terapkan boon "Wolf's Grin"
		calculated_damage *= stats.possess_damage
	
	# Terapkan boon 'final_damage' (multiplikatif)
	calculated_damage *= stats.final_damage
	
	return calculated_damage
