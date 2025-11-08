extends Node2D
class_name AttackManager

signal critical_circle

@onready var my_stats: Stats = $"../Stats"

var crit_multiplier:float = 2.0
var enemy_stats:Stats = null
var crit_interval: Array = [0.63,0.76]

func attack(enemy:Node, time:float, damage:float = my_stats.get_final_damage()) -> void :
	var enemy_stats
	if enemy is CharacterBody2D :
		enemy_stats = enemy.get_node("Stats")
	else :
		enemy_stats= enemy.get_owner().get_node("Stats")
	if !enemy_stats :
		return
	if time>=crit_interval[0] and time <= crit_interval[1] :
		enemy_stats.take_damage(damage, crit_multiplier)
		emit_signal("critical_circle")
	else :
		enemy_stats.take_damage(damage)
