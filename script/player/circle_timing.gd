extends Node2D

@onready var player: CharacterBody2D = null
var possession_manager: PossessionManager
var dash_manager: DashManager
@onready var circle_animation: AnimationPlayer = $CircleAnimation

var possesion_target:Node = null

func _ready() -> void:
	if owner is Player:
		player=owner
	if player:
		possession_manager = player.get_node("PossessionManager") as PossessionManager
		dash_manager = player.get_node("DashManager") as DashManager
		possession_manager.possessed.connect(_on_possessed)
		dash_manager.exit_cycle_started.connect(_on_exit)

func _on_possessed(target) -> void :
	possesion_target = target
	circle_animation.stop()
	circle_animation.play("shrink_in")

func _on_exit() -> void:
	if !possesion_target:
		return
	
	circle_animation.pause()
	
	var duplicate = self.duplicate()
	possesion_target.add_child(duplicate, true)
	self.visible = false
	if dash_manager.auto_exit_possess_lock:
		duplicate.circle_animation.play("shrink_in")
		duplicate.circle_animation.advance(1.2)
		await duplicate.circle_animation.animation_finished
		duplicate.circle_animation.play("fade_out")
		await duplicate.circle_animation.animation_finished
	else :
		duplicate.circle_animation.play("fade_out")
		await duplicate.circle_animation.animation_finished
	duplicate.queue_free()
