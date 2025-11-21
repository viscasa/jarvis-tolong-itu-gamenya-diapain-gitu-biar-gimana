extends Camera2D

var _shake_strength: float = 0.0
var _shake_fade: float = 5.0
var _rng = RandomNumberGenerator.new()

func _process(delta):
	if _shake_strength > 0:
		_shake_strength = lerp(_shake_strength, 0.0, _shake_fade * delta)
		
		offset = _random_offset()
	else:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO

func apply_shake(random_strength: float, duration: float = 0.2):
	_shake_strength = random_strength
	if duration > 0:
		_shake_fade = strength_to_fade(random_strength, duration)
	else:
		_shake_fade = 5.0

func strength_to_fade(start_strength: float, duration: float) -> float:
	return start_strength / (duration * start_strength * 0.1 + 0.01) # Approksimasi

func _random_offset() -> Vector2:
	return Vector2(
		_rng.randf_range(-_shake_strength, _shake_strength),
		_rng.randf_range(-_shake_strength, _shake_strength)
	)
