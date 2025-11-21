extends Node2D

func _ready() -> void:
	AudioManager.background_music.play()
	AudioManager.change_bgm_to_calm()



	
func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/story/introduction_story.tscn")



func _on_exit_button_pressed() -> void:
	get_tree().quit()
