extends BaseButton
class_name AnimatedButton

@export var hover_scale: Vector2 = Vector2(1.1, 1.1) 
@export var normal_scale: Vector2 = Vector2(1.0, 1.0) 
@export var animation_duration: float = 0.1 

var _tween: Tween

func _ready() -> void:
	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	pressed.connect(_on_pressed)
	
	scale = normal_scale

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size / 2.0

func _on_mouse_entered() -> void:
	_animate_scale(hover_scale)

func _on_mouse_exited() -> void:
	_animate_scale(normal_scale)

func _on_pressed() -> void:
	if _tween: _tween.kill()
	
	_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	_tween.tween_property(self, "scale", normal_scale * 0.95, 0.05)
	_tween.tween_property(self, "scale", hover_scale, 0.05)

func _animate_scale(target_scale: Vector2) -> void:
	if _tween:
		_tween.kill()
	
	_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "scale", target_scale, animation_duration)
