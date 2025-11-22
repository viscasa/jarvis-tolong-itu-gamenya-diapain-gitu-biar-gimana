extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var skip_button: AnimatedButton = $SkipButton
@onready var skip_label: RichTextLabel = $SkipButton/SkipLabel 

var inactivity_timeout := 2.0
var _inactivity_timer: Timer
var _skip_tween: Tween

func _ready() -> void:
	animation_player.play("introduction_story")
	_init_inactivity_timer()
	_hide_skip_label_immediate()

func _init_inactivity_timer() -> void:
	_inactivity_timer = Timer.new()
	_inactivity_timer.wait_time = inactivity_timeout
	_inactivity_timer.one_shot = true
	_inactivity_timer.timeout.connect(_on_inactivity_timeout)
	add_child(_inactivity_timer)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_on_mouse_moved()

func _on_mouse_moved() -> void:
	_show_skip_label()
	_restart_inactivity_timer()

func _restart_inactivity_timer() -> void:
	if _inactivity_timer.is_stopped() == false:
		_inactivity_timer.stop()
	_inactivity_timer.start()

func _on_inactivity_timeout() -> void:
	_hide_skip_label()

func _show_skip_label() -> void:
	skip_button.disabled = false
	skip_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_tween_visible_ratio(1.0)

func _hide_skip_label() -> void:
	skip_button.disabled = true
	skip_button.mouse_default_cursor_shape = Control.CURSOR_ARROW
	_tween_visible_ratio(0.0)

func _hide_skip_label_immediate() -> void:
	skip_button.disabled = true
	if skip_label.has_method("set_visible_ratio"):
		skip_label.visible_ratio = 0.0
	elif skip_label.has_method("set_modulate"):
		skip_label.modulate.a = 0.0

func _tween_visible_ratio(target: float, duration: float = 0.3) -> void:
	if _skip_tween:
		_skip_tween.kill()
	_skip_tween = create_tween()
	if skip_label.has_method("set_visible_ratio"):
		_skip_tween.tween_property(skip_label, "visible_ratio", target, duration)
	else:
		_skip_tween.tween_property(skip_label, "modulate:a", target, duration)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	get_tree().change_scene_to_file("res://scene/level/tutorial_level.tscn")

func _on_skip_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scene/level/tutorial_level.tscn")
