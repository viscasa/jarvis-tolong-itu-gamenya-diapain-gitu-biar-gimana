extends CanvasLayer
@onready var continue_button: Button = $ContinueButton
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var boon_grid: GridContainer = $BoonGrid
@onready var boon_name_label: Label = $BoonNameLabel
@onready var boon_desc_label: Label = $BoonDescLabel
var player_buff_manager: PlayerBuffManager = null
var boon_icon_scene = preload("res://scene/menu/boon_icon.tscn")
func _ready():
	continue_button.pressed.connect(_on_continue_pressed)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("BuffManager"):
		player_buff_manager = player.get_node("BuffManager")
	
	_update_boon_list()

func _unhandled_input(event: InputEvent) -> void:
	if (RewardManager.showing_reward_screen):
		return
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
	if get_tree().paused:
		if event.is_action_pressed("ui_accept"):
			_toggle_pause()
func _on_continue_pressed():
	_toggle_pause()
	
func _toggle_pause():
	_update_boon_list()
	
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

func _update_boon_list():
	if not is_instance_valid(player_buff_manager):
		return

	for child in boon_grid.get_children():
		child.queue_free()

	var current_boons = player_buff_manager.list_of_buffs
	
	if current_boons.is_empty():
		boon_name_label.text = "You have no boons."
		boon_desc_label.text = "Defeat enemies and collect rewards to gain boons."
		return
	boon_name_label.text = "Boon name."
	boon_desc_label.text = "Hover to a boon icon to see its effects"
	for boon in current_boons:
		var icon = boon_icon_scene.instantiate()
		icon.set_boon_data(boon)
		
		icon.boon_hovered.connect(_on_boon_icon_hovered)
		
		boon_grid.add_child(icon)

# Callback saat ikon di-hover
func _on_boon_icon_hovered(boon_data: BuffBase):
	boon_name_label.text = boon_data.boon_name
	boon_desc_label.text = boon_data.boon_description
