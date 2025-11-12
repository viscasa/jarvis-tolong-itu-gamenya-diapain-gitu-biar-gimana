extends Resource
class_name BuffBase

@export_enum("Hood", "Rabbit", "Wizard", "Pig", "Cinderalla") var buff_type: String = "Hood"
@export var boon_name: String = "Nama Boon"
@export var boon_description: String = "Deskripsi boon..."
@export var modifier: PlayerModifier = PlayerModifier.new()
@export var permanent: bool = true
@export var duration: float = 0.0
@export var boon_icon: Texture
@export var icon_id := 1
var time_left: float = 0.0

func _init():
	if !permanent:
		time_left = duration

func apply_buff(player_mod: PlayerModifier) -> PlayerModifier:
	return player_mod.add(modifier)

func update(delta: float):
	if duration > 0:
		time_left = max(0, time_left - delta)
