@tool
extends Polygon2D

@export var width: float = 256.0
@export var height: float = 128.0
@export var sides: int = 48

func _ready():
	var points = []
	for i in range(sides):
		var angle = i * TAU / sides
		var x = cos(angle) * width / 2
		var y = sin(angle) * height / 2
		points.append(Vector2(x, y))
	polygon = points
