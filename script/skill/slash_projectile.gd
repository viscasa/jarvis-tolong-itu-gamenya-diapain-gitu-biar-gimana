extends CharacterBody2D
class_name SlashProjectile

# Variabel ini akan di-set oleh SlashShot.gd
var speed: float = 600.0
var damage: float = 25.0
var lifetime: float = 0.25
var direction: Vector2 = Vector2.RIGHT

@onready var timer: Timer = $Timer

# Array untuk melacak musuh yang sudah terkena tebasan ini
var bodies_hit: Array = []

func _ready() -> void:
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	timer.start()

func launch(_initial_direction: Vector2):
	direction = _initial_direction.normalized()
	rotation = direction.angle() # Arahkan visual tebasan

func _physics_process(delta: float) -> void:
	# Bergerak lurus ke depan
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
	enemy_stats.take_damage(damage)
	bodies_hit.append(body) # Tandai sudah kena
