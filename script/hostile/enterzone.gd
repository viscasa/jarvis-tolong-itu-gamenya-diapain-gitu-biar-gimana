extends Area2D
@export var one_use := true

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	print(body)
	if body == null or not body.has_node("PossessionManager"):
		return
	var dm = body.get_node("DashManager")
	var pm = body.get_node("PossessionManager")

	var allowed := false
	if dm.must_exit_before_possession:
		allowed = dm.has_exited_since_last_possession
	else:
		# Gerak atau masih dalam jendela siklus
		allowed = dm.is_dashing or dm.is_exit_dashing or dm.dash_cycle_active or dm.exit_dash_cycle_active

	if allowed:
		pm.possess(self)
