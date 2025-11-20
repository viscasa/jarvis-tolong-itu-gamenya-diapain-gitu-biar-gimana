extends CanvasLayer
@onready var character_animations: AnimationPlayer = $CharacterAnimations
@onready var ruby: Sprite2D = $Characters/Ruby
@onready var peter: Sprite2D = $Characters/Peter
@onready var _3_pigs: Sprite2D = $"Characters/3Pigs"
@onready var isolde: Sprite2D = $Characters/Isolde
@onready var cinderella: Sprite2D = $Characters/Cinderella
# untuk show character, beri signal di timeline 
# beri signal hide diakhir timeline untuk menghilangkan karakter ketiga dialog selesai, kecuali emang ingin tetap ada seperti pengambilan boon (hide setelah ambil boon)
func _ready() -> void:
	Dialogic.signal_event.connect(_on_dialogic_signal)
func show_character():
	match Dialogic.VAR.currently_talking:
		"cinderella":
			cinderella.show()
		"ruby":
			ruby.show()
		"3pigs":
			_3_pigs.show()
		"isolde":
			isolde.show()
		"peter":
			peter.show()
	character_animations.play("character_fade_in")

func hide_character():
	character_animations.play_backwards("character_fade_in")
	await character_animations.animation_finished
	cinderella.hide()
	ruby.hide()
	_3_pigs.hide()
	isolde.hide()
	peter.hide()

func _on_dialogic_signal(arg: String):
	match arg:
		"hide_character":
			hide_character()
		"show_character":
			show_character()
