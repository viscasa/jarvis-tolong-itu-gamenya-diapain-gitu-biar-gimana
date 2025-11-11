extends Line2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func anim_vanish() -> void :
	animation_player.play("start_thunder")
