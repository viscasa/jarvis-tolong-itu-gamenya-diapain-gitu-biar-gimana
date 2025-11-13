extends TextureButton

signal boon_hovered(boon_data: BuffBase)

var held_boon: BuffBase = null

func _ready():
	mouse_entered.connect(_on_mouse_entered)

func set_boon_data(boon: BuffBase):
	held_boon = boon

	if boon.boon_icon:
		texture_normal = texture_normal.atlas
	else:
		print("ERROR: Boon '%s' tidak punya ikon!" % boon.boon_name)

func _on_mouse_entered():
	emit_signal("boon_hovered", held_boon)
