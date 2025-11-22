extends CharacterBody2D
class_name SlashProjectile

var speed: float = 2000
var damage: float = 25.0
var lifetime: float = 0.7
var direction: Vector2 = Vector2.RIGHT

@onready var timer: Timer = $Timer
@onready var particle: Node2D = $Particle

var bodies_hit: Array = []

func _ready() -> void:
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	timer.start()
	var tween = create_tween()
	tween.tween_property(particle, "modulate:a", 0, lifetime)
	

func launch(_initial_direction: Vector2):
	direction = _initial_direction.normalized()
	rotation = direction.angle() 

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func _on_area_2d_body_entered(body: Node2D) -> void:
	print(body)
	if body and body.is_in_group("player"):
		return
	
	var enemy_stats : Stats
	if body is CharacterBody2D :
		enemy_stats = body.get_node("Stats")
	else :
		enemy_stats= body.get_owner().get_node("Stats")
	if !enemy_stats :
		return
	var hit_direction = (body.global_position - global_position).normalized()
	enemy_stats.take_damage(damage, hit_direction)
	bodies_hit.append(body) 
