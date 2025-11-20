extends TextureButton

signal boon_hovered(boon_data: BuffBase)
@onready var boon_icon_texture: Node2D = $BoonIconTexture

var held_boon: BuffBase = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)
	boon_icon_texture.show_icon_no(held_boon.icon_id)

func set_boon_data(boon: BuffBase):
	held_boon = boon
	

func _on_mouse_entered():
	emit_signal("boon_hovered", held_boon)
