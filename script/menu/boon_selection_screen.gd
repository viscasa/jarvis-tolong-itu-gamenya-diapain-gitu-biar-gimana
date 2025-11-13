extends CanvasLayer

@onready var choice_container: VBoxContainer = $CenterContainer/ChoiceContainer
#@onready var boon_giver_name: Label = $BoonGiverName
@onready var rubymlbb: Sprite2D = $Rubymlbb
@onready var peter: Sprite2D = $Peter
@onready var _3_pigs: Sprite2D = $"3Pigs"
@onready var w_wo_tw: Sprite2D = $WWoTw
@onready var cinderella: Sprite2D = $Cinderella

var player_buff_manager: PlayerBuffManager
func _ready():
	# (Cari BuffManager player)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player_buff_manager = player.get_node("BuffManager")
# Dipanggil oleh BoonPickup.gd
func show_boon_choices(boon_giver_id: String):
	RewardManager.showing_reward_screen = true
	# 1. Minta boon yang SUDAH DIFILTER (anti-duplikat)
	var boon_choices = RewardManager.get_boon_choices(boon_giver_id, 3)
	
	# 2. Tampilkan boon di tombol-tombol
	print(choice_container)
	var buttons = choice_container.get_children()
	
	if boon_choices.is_empty():
		print("Tidak ada boon tersisa dari giver ini!")
		# (Tampilkan pesan "Sudah Habis" di UI)
		_close_ui()
		return
	if boon_giver_id == "cinderella":
		cinderella.show()
	elif boon_giver_id == "rabbit":
		peter.show()
	elif boon_giver_id == "pig":
		_3_pigs.show()
	elif boon_giver_id == "wizard":
		w_wo_tw.show()
	else:
		rubymlbb.show()
	#boon_giver_name.text = RewardManager.get_reward_data(boon_giver_id).name
	# Sembunyikan tombol yang tidak terpakai
	for i in range(buttons.size()):
		if i < boon_choices.size():
			buttons[i].set_boon_data(boon_choices[i])
			buttons[i].show()
		else:
			buttons[i].hide() # Sembunyikan jika sisa < 3

# Dipanggil oleh BoonChoiceButton.gd
func _on_boon_selected(boon: BuffBase):
	if player_buff_manager:
		player_buff_manager.add_buff(boon) # (duplicate() tidak perlu jika load())
	RewardManager.emit_signal("got_buff")
	_close_ui()

func _close_ui():
	get_tree().paused = false
	queue_free()
	RewardManager.showing_reward_screen = false


func _on_skip_button_pressed() -> void:
	RewardManager.emit_signal("got_buff")
	_close_ui()
