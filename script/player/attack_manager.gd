extends Node2D
class_name AttackManager

@onready var my_stats: Stats = $"../Stats"

var crit_multiplier:float = 2.0
var enemy_stats:Stats = null
var crit_interval: Array = [0.63,0.76]

func attack(enemy:Node, time:float) -> void :
	print(time)
	var enemy_stats = enemy.get_owner().get_node("Stats")
	if !enemy_stats :
		return
	if time>=crit_interval[0] and time <= crit_interval[1] :
		enemy_stats.take_damage(my_stats.get_final_damage(), crit_multiplier)
	else :
		enemy_stats.take_damage(my_stats.get_final_damage())
