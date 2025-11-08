extends Area2D
@export var one_use := true

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_node("PossessionManager"):
		return
	var dm = body.get_node("DashManager")
	var pm = body.get_node("PossessionManager")

	var allowed := false
	if dm.must_exit_before_possession:
		allowed = dm.has_exited_since_last_possession
	else:
		# boleh saat cycle aktif
		allowed = dm.is_dashing or dm.is_exit_dashing

	# ⛔ jangan possess kalau baru auto-exit dan masih terkunci
	if allowed and not dm.auto_exit_possess_lock:
		pm.possess(self)
