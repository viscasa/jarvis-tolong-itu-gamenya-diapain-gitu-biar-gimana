@tool
extends Area2D

var boon_giver_id: String = ""
@export_enum("Tree", "Orb") var sprite = 0
var selection_screen_scene = preload("res://scene/menu/boon_selection_screen.tscn")
@onready var sprite_1: Sprite2D = $Sprite1
@onready var sprite_2: Sprite2D = $Sprite2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var boon_giver_icon: Sprite2D = $BoonGiverIcon
var got_buff := false
func _ready():
	if (sprite == 0):
		sprite_1.show()
		sprite_2.hide()
	else:
		sprite_1.hide()
		sprite_2.show()
	body_entered.connect(_on_body_entered)
	RewardManager.got_buff.connect(_on_got_buff)
	
func set_boon_giver_id(id: String):
	boon_giver_id = id
	var reward_data = RewardManager.get_reward_data(id)
	boon_giver_icon.texture = load(reward_data.icon)
	boon_giver_icon.show()
	
func _on_body_entered(body):
	if got_buff:
		return
	if body is Player:
		print("Membuka UI Pilihan Boon untuk: ", boon_giver_id)

		# 1. Pause game
		get_tree().paused = true

		# 2. Buat instance UI
		var ui_screen = selection_screen_scene.instantiate()

		# 3. Beri tahu UI boon apa yang harus ditampilkan
		get_tree().root.add_child(ui_screen)
		ui_screen.show_boon_choices(boon_giver_id)

		# 4. Tampilkan UI

		# 5. Hancurkan objek pickup ini

func _on_got_buff():
	boon_giver_icon.hide()
	got_buff = true
