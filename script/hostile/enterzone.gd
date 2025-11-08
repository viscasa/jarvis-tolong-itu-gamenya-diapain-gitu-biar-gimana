extends Area2D

@export var one_use := true
var cooldown_possessed: float = 1.5

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body: Node) -> void:
	if body == null or not body.has_node("PossessionManager"):
		return
	var dm = body.get_node("DashManager")
	var pm = body.get_node("PossessionManager")

	var allowed := false
	allowed = dm.is_dashing or dm.is_exit_dashing

	# ⛔ jangan possess kalau baru auto-exit dan masih terkunci
	if allowed and not dm.auto_exit_possess_lock:
		set_collision_layer_value(1,false)
		set_collision_mask_value(1,false)
		pm.possess(self)
		await dm.exit_cycle_started
		await get_tree().create_timer(cooldown_possessed).timeout
		set_collision_layer_value(1,true)
		set_collision_mask_value(1,true)
