extends Node2D
class_name AttackManager

signal critical_circle

@export var base_damage: float = 10.0
@export var base_defense: float = 2.0
@export var damage_multiplier: float = 1.0

var crit_multiplier:float = 2.0
var enemy_stats:Stats = null


func attack(enemy:Node, is_critical: bool, damage:float = get_final_damage()) -> void :
	var enemy_stats
	if enemy is Scissor :
		return
	if enemy is CharacterBody2D :
		enemy_stats = enemy.get_node("Stats")
	else :
		enemy_stats= enemy.get_owner().get_node("Stats")
	if !enemy_stats :
		return
	if is_critical :
		enemy_stats.take_damage(damage, crit_multiplier)
		emit_signal("critical_circle")
	else :
		enemy_stats.take_damage(damage)

func get_final_damage() -> float:
	var final_damage = base_damage * damage_multiplier
	
	return final_damage
