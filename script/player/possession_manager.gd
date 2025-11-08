extends Node
class_name PossessionManager

signal possessed(target)

signal exit_dash_manual(target)   # manual exit (sukses)
signal auto_exit_dash             # auto exit (timeout / gagal)

var player: CharacterBody2D

var is_possessing: bool = false
var possessed_target: Node = null
var possession_timer: Timer = null

func possess(target: Node) -> void:
	# ⛔ blokir bila habis auto-exit dan lock masih aktif
	if player.dash_manager.auto_exit_possess_lock:
		return
	
	if is_possessing or (not player.dash_manager.is_dashing and not player.dash_manager.is_exit_dashing):
		return
		
	player.dash_manager.is_dashing = false
	player.dash_manager.is_exit_dashing = false

	if possession_timer:
		possession_timer.queue_free()
		possession_timer = null

	is_possessing = true
	possessed_target = target
	player.global_position = possessed_target.global_position
	player.velocity = Vector2.ZERO
	emit_signal("possessed", possessed_target)
	player.dash_manager.on_possession_started()
	if possessed_target.get_parent().has_method("on_possessed"):
		possessed_target.get_parent().on_possessed()
	# Timer for auto weak exit
	possession_timer = Timer.new()
	possession_timer.one_shot = true
	possession_timer.wait_time = 1.2
	player.add_child(possession_timer)
	possession_timer.connect("timeout", Callable(self, "_on_auto_exit"))
	possession_timer.start()


func _on_auto_exit() -> void:
	if possession_timer:
		possession_timer.queue_free()
		possession_timer = null

	if is_possessing:
		emit_signal("auto_exit_dash")
		release_possession()
		player.dash_manager.start_exit_dash(true, true)        # weak=true,  is_auto=true


func release_possession() -> void:
	if possessed_target and possessed_target.get_parent() and possessed_target.get_parent().has_method("on_released"):
		print("a")
		possessed_target.get_parent().on_released()
	is_possessing = false
	possessed_target = null
		
	if possession_timer:
		possession_timer.queue_free()
		possession_timer = null



func process_possession(delta: float) -> void:
	if possessed_target and is_instance_valid(possessed_target):
		player.global_position = possessed_target.global_position
		if Input.is_action_just_pressed("exit_dash"):
			emit_signal("exit_dash_manual", possessed_target)
			release_possession()
			player.dash_manager.start_exit_dash(false, false)   # weak=false, is_auto=false
	else:
		release_possession()
