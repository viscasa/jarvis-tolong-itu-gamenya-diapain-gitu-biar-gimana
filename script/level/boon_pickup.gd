@tool
extends Area2D

var boon_giver_id: String = ""
@export_enum("Tree", "Orb") var sprite = 0
var selection_screen_scene = preload("res://scene/menu/boon_selection_screen.tscn")
@onready var sprite_1: Sprite2D = $Sprite1
@onready var sprite_2: Sprite2D = $Sprite2

func _ready():
	if (sprite == 0):
		sprite_1.show()
		sprite_2.hide()
	else:
		sprite_1.hide()
		sprite_2.show()
	body_entered.connect(_on_body_entered)

func set_boon_giver_id(id: String):
	boon_giver_id = id

func _on_body_entered(body):
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
		queue_free()
