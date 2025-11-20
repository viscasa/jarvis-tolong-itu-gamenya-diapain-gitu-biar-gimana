extends Node
class_name Stats

signal health_changed(current_health, max_health)
signal no_health() 
signal was_hit(hit_direction: Vector2)

@export var max_health: float = 100.0
@export var base_damage: float = 10.0
@export var base_defense: float = 0.0
@export var health_bar : ProgressBar
@export var damage_multiplier: float = 1.0
@onready var damage_number_origin: Node2D = $"../DamageNumberOrigin"
@onready var animated_sprite_2d: AnimatedSprite2D = $"../AnimatedSprite2D"
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


func take_damage(damage_amount: float, hit_direction: Vector2,  crit_multiplier: float = 1.0):
	if is_death :
		return
	var final_damage = damage_amount*crit_multiplier - base_defense
	
	if final_damage < 1:
		final_damage = 1
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.3)
	var shake_tween = get_tree().create_tween()
	var shake_amount = 8.0 
	var shake_duration = 0.02
	var original_pos = animated_sprite_2d.position

	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos, shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos, shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(animated_sprite_2d, "position", original_pos, shake_duration)
	
	if crit_multiplier > 1.0:
		DamageNumber.display_number(final_damage, damage_number_origin, Color.YELLOW)
	else :
		DamageNumber.display_number(final_damage, damage_number_origin, Color.WHITE)
	current_health -= final_damage
	health_bar.value = current_health
	print(get_parent().name + " takes " + str(final_damage) + " damage. Health: " + str(current_health))
	was_hit.emit(hit_direction)
func set_shader_blink_intensity(new_value : float):
	animated_sprite_2d.material.set_shader_parameter("blink_intensity", new_value)
func get_final_damage() -> float:
	var final_damage = base_damage * damage_multiplier
	
	return final_damage
