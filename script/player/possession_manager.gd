extends Node
class_name PossessionManager

signal possessed(target)

var player: CharacterBody2D

var is_possessing: bool = false
var possessed_target: Node = null
var possession_timer: Timer = null

func possess(target: Node) -> void:
	if is_possessing or (not player.dash_manager.is_dashing and not player.dash_manager.is_exit_dashing):
		return

	player.dash_manager.is_dashing = false
	player.dash_manager.is_exit_dashing = false

	if possession_timer:
		possession_timer.queue_free()
		possession_timer = null

	is_possessing = true
	possessed_target = target
	player.global_position = target.global_position
	player.velocity = Vector2.ZERO
	emit_signal("possessed", target)
	player.dash_manager.on_possession_started()

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
		release_possession()
		player.dash_manager.start_exit_dash(true)


func release_possession() -> void:
	is_possessing = false
	possessed_target = null
	if possession_timer:
		possession_timer.queue_free()
		possession_timer = null


func process_possession(delta: float) -> void:
	if possessed_target and is_instance_valid(possessed_target):
		player.global_position = possessed_target.global_position
		if Input.is_action_just_pressed("exit_dash"):
			release_possession()
			player.dash_manager.start_exit_dash()
	else:
		release_possession()
