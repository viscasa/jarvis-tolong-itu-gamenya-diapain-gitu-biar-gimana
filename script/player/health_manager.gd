extends Node2D
class_name HealthManager

signal health_changed(current_health, max_health)
signal no_health() 

@export var max_health: float = 100.0
@export var base_defense: float = 2.0
@export var health_bar : ProgressBar
@export var heal_amount : float = 10.0
@onready var damage_number_origin: Node2D = $"../DamageNumberOrigin"

var current_health: float:
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		if current_health == 0:
			no_health.emit()

func _ready():
	current_health = max_health

func heal():
	current_health += heal_amount
	DamageNumber.display_number(heal_amount, damage_number_origin, Color.GREEN, true)
	health_bar.value = current_health

func take_damage(damage_amount: float, crit_multiplier: float = 1.0):
	var final_damage = damage_amount*crit_multiplier - base_defense
	
	if final_damage < 1:
		final_damage = 1
	
	if crit_multiplier > 1.0:
		DamageNumber.display_number(final_damage, damage_number_origin, Color.RED)
	else :
		DamageNumber.display_number(final_damage, damage_number_origin, Color.RED)
	current_health -= final_damage
	health_bar.value = current_health
