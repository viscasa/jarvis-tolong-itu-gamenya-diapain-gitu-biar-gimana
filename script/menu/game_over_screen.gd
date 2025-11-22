extends CanvasLayer
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	await get_tree().create_timer(2.0).timeout
	animation_player.play("game_over")
func _on_exit_button_pressed() -> void:
	get_tree().quit()



func _on_yes_button_pressed() -> void:
	PlayerBuffManager.reset_all_buffs()
	get_tree().change_scene_to_file("res://scene/level/tutorial_level.tscn")
