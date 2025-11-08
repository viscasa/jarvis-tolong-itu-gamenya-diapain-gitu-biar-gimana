# Wolf.gd
extends EnemyBase

@export var dash_speed: float = 400.0
@export var charge_time: float = 0.5   
@export var dash_duration: float = 0.3 

enum WolfAttackState { CHARGING, DASHING, RECOVERING }
var wolf_attack_state: WolfAttackState = WolfAttackState.RECOVERING

var charge_timer: float = 0.0
var dash_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO

#func _state_chase(delta):
	#var distance_to_player = global_position.distance_to(player_target.global_position)
	#var direction_to_player = global_position.direction_to(player_target.global_position)
#
	#if distance_to_player > attack_range:
		#velocity = direction_to_player * move_speed
		##animated_sprite.play("walk")
	#else:
		#velocity = Vector2.ZERO
		##animated_sprite.play("idle")
#
	#if velocity.x != 0:
		#animated_sprite.flip_h = (velocity.x < 0)



func _perform_attack():
	if wolf_attack_state != WolfAttackState.RECOVERING:
		return

	wolf_attack_state = WolfAttackState.CHARGING
	charge_timer = charge_time
	#animated_sprite.play("charge") 
	
	dash_direction = global_position.direction_to(player_target.global_position)
	
	if dash_direction.x != 0:
		animated_sprite.flip_h = (dash_direction.x < 0)

func _state_attack(delta):
	match wolf_attack_state:
		
		WolfAttackState.CHARGING:
			velocity = Vector2.ZERO
			charge_timer -= delta
			
			if charge_timer <= 0:
				wolf_attack_state = WolfAttackState.DASHING
				dash_timer = dash_duration
				#animated_sprite.play("dash") 
				
				hitbox.damage = stats.get_final_damage()
				hitbox_shape.disabled = false
		
		WolfAttackState.DASHING:
			velocity = dash_direction * dash_speed
			dash_timer -= delta
			
			if dash_timer <= 0:
				wolf_attack_state = WolfAttackState.RECOVERING
				#animated_sprite.play("idle")
				
				if self and hitbox_shape:
					hitbox_shape.disabled = true
		
		WolfAttackState.RECOVERING:
			velocity = Vector2.ZERO
			


func _on_attack_timer_timeout():
	super._on_attack_timer_timeout()
	
	wolf_attack_state = WolfAttackState.RECOVERING
	
	if self and hitbox_shape:
		hitbox_shape.disabled = true
