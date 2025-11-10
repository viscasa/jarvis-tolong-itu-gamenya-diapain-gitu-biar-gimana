extends Node2D


func _on_start_button_pressed() -> void:
	pass
	#TODO ganti ke path scene tutorial/prolog
	#get_tree().change_scene_to_file("")



func _on_exit_button_pressed() -> void:
	get_tree().quit()
