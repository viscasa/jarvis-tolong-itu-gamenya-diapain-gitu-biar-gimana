extends Area2D
class_name Door

@export var next_scene_path: String = ""

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var reward_icon: Sprite2D = $RewardIcon

var is_locked: bool = true
var assigned_reward_id := ""
func _ready():
	body_entered.connect(_on_body_entered)
	reward_icon.hide()

func lock():
	is_locked = true
	modulate = Color.DARK_GRAY
	# sprite.play("locked") 
		
	reward_icon.hide()

func unlock(reward_id := "", icon_texture: Texture = null):
	modulate = Color.WHITE
	is_locked = false
	# sprite.play("unlocked")
	assigned_reward_id = reward_id
	reward_icon.texture = icon_texture
	reward_icon.show()

func _on_body_entered(body):
	if body is Player and not is_locked:
		RewardManager.next_reward_id = assigned_reward_id
		get_tree().change_scene_to_file(next_scene_path)
		
