extends Area2D
class_name BoonPickup

var boon_giver_id: String = ""
@export_enum("Tree", "Orb") var sprite = 0
var selection_screen_scene = preload("res://scene/menu/boon_selection_screen.tscn")
@onready var sprite_1: Sprite2D = $Sprite1
@onready var sprite_2: Sprite2D = $Sprite2
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var boon_giver_icon: Node2D = $BoonGiverIcon
@onready var cinderella_icon: AnimatedSprite2D = $BoonGiverIcon/CinderellaIcon
@onready var red_riding_icon: AnimatedSprite2D = $BoonGiverIcon/RedRidingIcon
@onready var pig_icon: AnimatedSprite2D = $BoonGiverIcon/PigIcon
@onready var rabbit_icon: AnimatedSprite2D = $BoonGiverIcon/RabbitIcon
@onready var wizard_icon: AnimatedSprite2D = $BoonGiverIcon/WizardIcon
var got_buff := false

signal boon_picked

func _ready():
	var sprite_material = sprite_1.material
	sprite_material.set_shader_parameter("frequency", 0.0)
	if (sprite == 0):
		sprite_1.show()
		sprite_2.hide()
	else:
		sprite_1.hide()
		sprite_2.show()
	body_entered.connect(_on_body_entered)
	RewardManager.got_buff.connect(_on_got_buff)
	
func set_boon_giver_id(id: String):
	var sprite_material = sprite_1.material
	boon_giver_id = id
	if id == "cinderella":
		cinderella_icon.show()
	elif id == "red_riding_hood":
		red_riding_icon.show()
	elif id == "pig":
		pig_icon.show()
	elif id == "rabbit":
		rabbit_icon.show()
	else:
		wizard_icon.show()
	boon_giver_icon.show()
	sprite_material.set_shader_parameter("frequency", 2.0)

func _on_body_entered(body):
	if got_buff:
		return
	if body is Player:
		print("Membuka UI Pilihan Boon untuk: ", boon_giver_id)

		get_tree().paused = true

		var ui_screen = selection_screen_scene.instantiate()

		get_tree().root.add_child(ui_screen)
		ui_screen.show_boon_choices(boon_giver_id)

func _on_got_buff():
	var sprite_material = sprite_1.material
	sprite_material.set_shader_parameter("frequency", 0.0)
	boon_giver_icon.hide()
	got_buff = true
	boon_picked.emit()
