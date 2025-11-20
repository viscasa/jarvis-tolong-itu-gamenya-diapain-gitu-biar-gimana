extends Node

var available_level : Array = [
	"res://scene/level/room_random_2.tscn",
	"res://scene/level/room_random_6.tscn"
]

var current_level = "res://scene/level/room_random_1.tscn"

func get_next_level() :
	var path = available_level.pick_random()
	available_level.erase(path)
	available_level.append(current_level)
	current_level = path
	return path
