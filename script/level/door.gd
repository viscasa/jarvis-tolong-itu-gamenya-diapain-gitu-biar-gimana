extends Area2D
class_name Door

@export var next_scene_path: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var boon_giver_icon: Node2D = $BoonGiverIcon
@onready var cinderella_icon: AnimatedSprite2D = $BoonGiverIcon/CinderellaIcon
@onready var red_riding_icon: AnimatedSprite2D = $BoonGiverIcon/RedRidingIcon
@onready var pig_icon: AnimatedSprite2D = $BoonGiverIcon/PigIcon
@onready var rabbit_icon: AnimatedSprite2D = $BoonGiverIcon/RabbitIcon
@onready var wizard_icon: AnimatedSprite2D = $BoonGiverIcon/WizardIcon

var is_locked: bool = true
var assigned_reward_id := ""
func _ready():
	body_entered.connect(_on_body_entered)
	boon_giver_icon.hide()

func lock():
	is_locked = true
	modulate = Color.DARK_GRAY
	# sprite.play("locked") 
		
	boon_giver_icon.hide()

func unlock(reward_id := "", icon_texture: Texture = null):
	if reward_id == "cinderella":
		cinderella_icon.show()
	elif reward_id == "red_riding_hood":
		red_riding_icon.show()
	elif reward_id == "pig":
		pig_icon.show()
	elif reward_id == "rabbit":
		rabbit_icon.show()
	else:
		wizard_icon.show()
	modulate = Color.WHITE
	is_locked = false
	# sprite.play("unlocked")
	assigned_reward_id = reward_id
	boon_giver_icon.show()

func _on_body_entered(body):
	if body is Player and not is_locked:
		RewardManager.next_reward_id = assigned_reward_id
		get_tree().change_scene_to_file(next_scene_path)
		
