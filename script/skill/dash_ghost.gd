extends Sprite2D

@export var color : Color

func _ready() -> void:
	material.set_shader_parameter("custom_color", color)
	self_modulate.a = 1.0
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(3)
	await tween.finished
	queue_free()
