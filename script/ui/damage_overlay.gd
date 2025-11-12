extends CanvasLayer

@onready var material = $ColorRect.material
var tween
func flash():
	if tween: tween.kill()
	tween = create_tween()
	material.set_shader_parameter("intensity", 1.0)
	tween.tween_property(material, "shader_parameter/intensity", 0.0, 0.4)
