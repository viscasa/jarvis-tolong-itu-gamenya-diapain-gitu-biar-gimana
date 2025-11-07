extends Area2D
@export var one_use := true

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	print(self)
	if body == null or not body.has_node("PossessionManager"):
		return

	var dash_manager = body.get_node("DashManager")
	var possession_manager = body.get_node("PossessionManager")

	# Kita cek apakah player sedang 'dashing' ATAU 'exit dashing'
	if dash_manager and (dash_manager.is_dashing or dash_manager.is_exit_dashing):
		possession_manager.possess(self)
		print(self, "2")
