extends CanvasLayer

@onready var choice_container: VBoxContainer = $CenterContainer/ChoiceContainer
#@onready var boon_giver_name: Label = $BoonGiverName


func _ready():
	# (Cari BuffManager player)
	var player = get_tree().get_first_node_in_group("player")
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
		
	var layout_node = null
	Dialogic.VAR.random_dialog = randi() % 3 + 1
	if boon_giver_id == "cinderella":
		layout_node = Dialogic.start("cinderella_boon")
	elif boon_giver_id == "rabbit":
		layout_node = Dialogic.start("rabbit_boon")
	elif boon_giver_id == "pig":
		layout_node = Dialogic.start("pig_boon")
	elif boon_giver_id == "wizard":
		layout_node = Dialogic.start("wizard_boon")
	else:
		layout_node = Dialogic.start("red_riding_hood_boon")
	
	if layout_node:
		layout_node.process_mode = Node.PROCESS_MODE_ALWAYS
		
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
	print("got boon a")
	PlayerBuffManager.add_buff(boon) # (duplicate() tidak perlu jika load())
	RewardManager.emit_signal("got_buff")
	DialogCharacter.hide_character()
	_close_ui()

func _close_ui():
	get_tree().paused = false
	queue_free()
	RewardManager.showing_reward_screen = false


func _on_skip_button_pressed() -> void:
	RewardManager.emit_signal("got_buff")
	_close_ui()
