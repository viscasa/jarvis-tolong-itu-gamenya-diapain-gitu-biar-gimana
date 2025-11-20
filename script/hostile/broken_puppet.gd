extends EnemyBase

@export var lunge_speed: float = 150.0

@export var lunge_duration: float = 0.2 

var lunge_direction: Vector2 = Vector2.ZERO
var lunge_timer: float = 0.0
var original_hitbox_position: Vector2 = Vector2.ZERO
@export var attack_offset: float = 20.0

func _ready():
	super._ready() 
	original_hitbox_position = hitbox.position
func _perform_attack():
	if is_instance_valid(player_target):
		lunge_direction = global_position.direction_to(player_target.global_position)
	else:
		lunge_direction = Vector2.RIGHT
	
	lunge_timer = lunge_duration
	hitbox.rotation = lunge_direction.angle() + rad_to_deg(2)
	hitbox.position = lunge_direction * attack_offset
	
	super._perform_attack()

func _state_attack(delta):
	if is_in_knockback:
		var requested_velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		nav_agent.set_velocity(requested_velocity)
		return

	var target_velocity: Vector2
	
	if lunge_timer > 0:
		target_velocity = lunge_direction * lunge_speed
		lunge_timer -= delta
	else:
		target_velocity = Vector2.ZERO

	var requested_velocity = velocity.lerp(target_velocity, 15.0 * delta)
	nav_agent.set_velocity(requested_velocity)
	
