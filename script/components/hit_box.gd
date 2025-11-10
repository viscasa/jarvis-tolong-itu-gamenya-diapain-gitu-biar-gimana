extends Area2D
class_name Hitbox

var damage: float = 0.0
func _ready() -> void:
	area_entered.connect(_area_entered)

func _area_entered(area: Area2D) -> void:
	if area is HurtboxPlayer:
		if area.get_parent() is Player:
			var stats_node = area.get_parent().get_node_or_null("HealthManager")
			if stats_node:
				stats_node.take_damage(damage)
