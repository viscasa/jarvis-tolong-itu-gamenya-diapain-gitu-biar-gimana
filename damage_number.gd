extends Node

var randomize_x_interval : Array = [-20,20]
var randomize_y_interval : Array = [-20,0]

func display_number(value: int, damage_number_origin: Node2D, color: Color = Color.WHITE):
	var number = Label.new()
	
	number.position = Vector2(randf_range(randomize_x_interval[0],randomize_x_interval[1]), randf_range(randomize_y_interval[0],randomize_y_interval[1]))
	number.text = str(value)
	number.z_index = 5
	number.label_settings = LabelSettings.new()
	
	number.label_settings.font_color = color
	number.label_settings.font_size = 10
	number.label_settings.outline_color = "#000"
	number.label_settings.outline_size = 1
	
	damage_number_origin.add_child(number)
	
	number.pivot_offset = Vector2(number.size/2)
	
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		number, "position:y", number.position.y - 24, 0.25
	).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		number, "position:y", number.position.y, 0.5
	).set_ease(Tween.EASE_IN).set_delay(0.4)
	tween.tween_property(
		number, "scale", Vector2.ZERO, 0.25
	).set_ease(Tween.EASE_IN).set_delay(0.9)
	
	await tween.finished 
	number.queue_free()
