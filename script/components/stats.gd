extends Node
class_name Stats

signal health_changed(current_health, max_health)
signal no_health() 

@export var max_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_defense: float = 2.0
@export var health_bar : ProgressBar
@export var damage_multiplier: float = 1.0
@onready var damage_number_origin: Node2D = $"../DamageNumberOrigin"
var is_death = false

var current_health: float:
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health <= 0:
			no_health.emit()
			is_death = true


func _ready():
	current_health = max_health


func take_damage(damage_amount: float, crit_multiplier: float = 1.0):
	if is_death :
		return
	var final_damage = damage_amount*crit_multiplier - base_defense
	
	if final_damage < 1:
		final_damage = 1
	
	if crit_multiplier > 1.0:
		DamageNumber.display_number(final_damage, damage_number_origin, Color.RED)
	else :
		DamageNumber.display_number(final_damage, damage_number_origin, Color.WHITE)
	current_health -= final_damage
	health_bar.value = current_health
	print(get_parent().name + " takes " + str(final_damage) + " damage. Health: " + str(current_health))

func get_final_damage() -> float:
	var final_damage = base_damage * damage_multiplier
	
	return final_damage

#func add_buff(buff: BuffResource):
	#active_buffs.append(buff)
	## TODO: 
	## ...
#
#func remove_buff(buff: BuffResource):
	#active_buffs.erase(buff)
