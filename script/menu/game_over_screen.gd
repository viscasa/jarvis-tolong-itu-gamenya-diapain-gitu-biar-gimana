extends CanvasLayer


func _on_exit_button_pressed() -> void:
	get_tree().quit()



func _on_yes_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level/tutorial_level.tscn")
