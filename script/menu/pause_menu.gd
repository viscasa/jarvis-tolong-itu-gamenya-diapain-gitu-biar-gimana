extends CanvasLayer
@onready var continue_button: Button = $ContinueButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	continue_button.pressed.connect(_on_continue_pressed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
	if get_tree().paused:
		if event.is_action_pressed("ui_accept"):
			_toggle_pause()
func _on_continue_pressed():
	_toggle_pause()
	
func _toggle_pause():
	var paused  = get_tree().paused

	if not paused:
		animation_player.play("pause")
		print("Game Paused")
		await animation_player.animation_finished
		get_tree().paused = true
	else:
		animation_player.play_backwards("pause")
		print("Game Resumed")
		await animation_player.animation_finished
		get_tree().paused = false
		
