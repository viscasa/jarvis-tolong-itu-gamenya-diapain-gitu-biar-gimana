extends CharacterBody2D
class_name ThrownPin

@onready var stats: Stats = $Stats
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_timer: Timer = $AttackTimer
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 

var speed: float = 0.0
var direction: Vector2 = Vector2.ZERO
var distance_to_travel: float = 0.0
var damage: float = 10.0
var duration: float = 3

var travel_timer: float = 0.0 

func launch(_direction: Vector2, _speed: float, _distance: float):
	direction = _direction
	speed = _speed
	distance_to_travel = _distance
	
	if speed > 0.0:
		travel_timer = distance_to_travel / speed
	else:
		travel_timer = 0.0
		
	velocity = direction * speed
	
	attack_timer.start(duration)

func _ready() -> void:
	current_state = State.ATTACK
	add_to_group("enemies")
	animated_sprite_2d.material.set_shader_parameter('percentage', 1.0)
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	stats.no_health.connect(_on_death)

func _physics_process(delta: float) -> void:
	
	if travel_timer > 0.0:
		travel_timer -= delta
		
		move_and_slide()
		
		if get_slide_collision_count() > 0:
			_stop_movement()
		
		elif travel_timer <= 0.0:
			_stop_movement()
			
	else:
		velocity = Vector2.ZERO
		move_and_slide() 

func _stop_movement() -> void:
	travel_timer = 0.0
	speed = 0.0 
	velocity = Vector2.ZERO 

func _on_death():
	current_state = State.DEAD
	hitbox_collision.set_deferred("disabled", true)
	hurtbox_collision.set_deferred("disabled", true)
	body_collision.set_deferred("disabled", true)
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		var player = player_nodes[0]
		player.get_node("SkillManager").add_pin()
	
	set_physics_process(false)
	tween_percent()

func _on_attack_timer_timeout() -> void:
	hurtbox_collision.disabled = true
	body_collision.disabled = true
	_on_death()

func _on_hurtbox_player_auto_exit() -> void:
	attack_timer.start(duration)
	
func _on_hurtbox_player_possessed() -> void:
	attack_timer.stop()

func set_percent(percentage: float) -> void:
	animated_sprite_2d.material.set_shader_parameter('percentage', percentage)

func tween_percent():
	var tween = create_tween()
	tween.tween_method(set_percent, 1.0, 0.0, 0.4)
	await tween.finished
	queue_free()
