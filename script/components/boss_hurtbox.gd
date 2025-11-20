extends Hurtbox

func _on_area_entered(area):
	if area is Hitbox:
		var stats_node = get_parent().get_node_or_null("Stats")
		
		if stats_node:
			stats_node.take_damage(area.damage)
