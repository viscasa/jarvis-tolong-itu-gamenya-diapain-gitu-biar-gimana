extends CharacterBody2D
class_name Scissor

@export var homing_speed: float = 100.0 
@export var homing_duration: float = 5.0 
@export var lifetime_after_homing: float = 3.0

@export var turn_speed: float = 5.0 

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var homing_timer: Timer = $HomingTimer

var player_target: CharacterBody2D = null
var current_direction: Vector2 = Vector2.DOWN 
enum State { HOMING, STRAIGHT}
var state: State = State.HOMING
var damage: float = 10.0 

func _ready():
	player_target = get_tree().get_first_node_in_group("player")
	
	homing_timer.wait_time = homing_duration
	homing_timer.one_shot = true
	homing_timer.timeout.connect(_on_homing_timer_timeout)
	homing_timer.start()
	
	hitbox.body_entered.connect(_on_hitbox_body_entered)
	
	if is_instance_valid(player_target):
		current_direction = global_position.direction_to(player_target.global_position)
	
	sprite.rotation = current_direction.angle()

func _physics_process(delta):
	if not is_instance_valid(player_target):
		queue_free() 
		return

	match state:
		State.HOMING:
			var ideal_direction = global_position.direction_to(player_target.global_position)
			
			current_direction = current_direction.lerp(ideal_direction, turn_speed * delta).normalized()
			velocity = current_direction * homing_speed
			sprite.rotation = current_direction.angle()

		State.STRAIGHT:
			velocity = current_direction * homing_speed

	move_and_slide()
	
	var collision = get_last_slide_collision()
	if collision:
		if collision.get_collider() is TileMapLayer:
			queue_free()

func _on_homing_timer_timeout():
	state = State.STRAIGHT
	
	var lifetime_timer = Timer.new()
	lifetime_timer.wait_time = lifetime_after_homing
	lifetime_timer.one_shot = true
	lifetime_timer.timeout.connect(queue_free)
	add_child(lifetime_timer)
	lifetime_timer.start()

func _on_hitbox_body_entered(body):
	if body is Player:
		var stats = body.get_node_or_null("Stats")
		if stats:
			stats.take_damage(damage)
		queue_free()
	
	if body is EnemyBase:
		if body is Geppetto:
			return
			
		var stats = body.get_node_or_null("Stats")
		if stats:
			stats.take_damage(damage)
		queue_free() 
