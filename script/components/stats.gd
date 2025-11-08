extends Node
class_name Stats

signal health_changed(current_health, max_health)
signal no_health() 

@export var max_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_defense: float = 2.0

var current_health: float:
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health == 0:
			no_health.emit()


func _ready():
	current_health = max_health


func take_damage(damage_amount: float):
	var final_damage = damage_amount - base_defense
	
	if final_damage < 1:
		final_damage = 1
		
	current_health -= final_damage
	print(get_parent().name + " takes " + str(final_damage) + " damage. Health: " + str(current_health))

func get_final_damage() -> float:
	var final_damage = base_damage
	

			
	return final_damage

#func add_buff(buff: BuffResource):
	#active_buffs.append(buff)
	## TODO: 
	## ...
#
#func remove_buff(buff: BuffResource):
	#active_buffs.erase(buff)
