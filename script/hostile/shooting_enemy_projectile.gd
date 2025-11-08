extends Area2D
class_name Projectile

@export var speed: float = 350.0

var damage: float = 0.0
var direction: Vector2 = Vector2.ZERO

@onready var notifier = $VisibleOnScreenNotifier2D

func _ready():
	area_entered.connect(_on_area_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	
	rotation = direction.angle()

func _physics_process(delta):
	global_position += direction * speed * delta

func _on_area_entered(area):
	if area is Hurtbox:
		if area.get_parent() is Player:
			
			var stats_node = area.get_parent().get_node_or_null("Stats")
			
			if stats_node:
				stats_node.take_damage(damage)
			
			queue_free()

func _on_screen_exited():
	queue_free()
