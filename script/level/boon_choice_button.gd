extends Button

var held_boon: BuffBase = null # Boon .tres yang dipegang

@onready var name_label: Label = $NameLabel
@onready var desc_label: Label = $DescriptionLabel
@onready var boon_icon_texture: Node2D = $BoonIconTexture

func _ready():
	pressed.connect(_on_pressed)

func set_boon_data(boon: BuffBase):
	held_boon = boon
	name_label.text = boon.boon_name
	desc_label.text = boon.boon_description
	#  set ikon boon di sini #TODO

func _on_pressed():
	find_parent("BoonSelectionScreen")._on_boon_selected(held_boon)
