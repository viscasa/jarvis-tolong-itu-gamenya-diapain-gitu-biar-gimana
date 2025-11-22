extends Node

var level_1 : Array = ["res://scene/level/1/1_rand_1.tscn", "res://scene/level/1/1_rand_2.tscn"]
var level_2 : Array = ["res://scene/level/2/2_rand_1.tscn", "res://scene/level/2/2_rand_2.tscn"]
var level_3 : Array = ["res://scene/level/3/3_rand_1.tscn", "res://scene/level/3/3_rand_2.tscn"]
var level_4 : Array = ["res://scene/level/4/4_rand_1.tscn", "res://scene/level/4/4_rand_2.tscn"]
var level_5 : Array = ["res://scene/level/5/5_rand_1.tscn", "res://scene/level/5/5_rand_2.tscn"]
var level_boss : Array = ["res://scene/level/geppetto_level.tscn"]
var level_counter : int = 0
var total_stage:int = 0

var current_level = "res://scene/level/1/1_rand_1.tscn"
func get_next_level() :
	print(level_counter)
	level_counter += 1
	total_stage += 1
	match level_counter:
		1:
			current_level = level_1.pick_random()
			return current_level
		2:
			current_level = level_2.pick_random()
			return current_level
		3:
			current_level = level_3.pick_random()
			return current_level
		4:
			current_level = level_4.pick_random()
			return current_level
		5:
			current_level = level_5.pick_random()
			return current_level
		6: 
			current_level = level_boss.pick_random()
			level_counter = 0
			return current_level
