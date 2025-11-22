extends StaticBody2D
@onready var hit_box: Hitbox = $HitBox

func _ready() -> void:
	hit_box.damage = 5.0
