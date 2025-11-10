extends Sprite2D

func _ready() -> void:
	var tween = get_tree().create_tween()
	self_modulate.a = 1.0
	tween.tween_property(self, "modulate:a", 0.0, 0.5).set_ease(3)
	await tween.finished
	queue_free()
