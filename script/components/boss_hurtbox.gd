extends Area2D
class_name BossHurtBox

func _on_area_entered(area):
	if area is Hitbox:
		var stats_node = get_parent().get_node_or_null("Stats")
		
		if stats_node:
			var hit_direction = (get_parent().global_position - area.global_position).normalized()
			stats_node.take_damage(area.damage, hit_direction)
		else:
			print("ERROR: " + get_parent().name + " tidak punya node Stats!")
