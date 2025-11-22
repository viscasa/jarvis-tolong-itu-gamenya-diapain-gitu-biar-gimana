extends CanvasLayer

var circle_shader_material: ShaderMaterial
@onready var color_rect: ColorRect = $ColorRect
var transition_active = false

signal transition_halfway
signal transition_complete

var next_scene_path: String = ""

func _ready() -> void:
	circle_shader_material = color_rect.material
	_update_size()
	get_tree().root.size_changed.connect(_update_size)

func _update_size():
	var viewport_size = get_viewport().get_visible_rect().size
	color_rect.size = viewport_size
	color_rect.position = Vector2.ZERO


func iris_transition(next_scene: String = "", start_pos: Vector2 = Vector2.ZERO):
	Engine.time_scale = 1.0
	if transition_active:
		return

	next_scene_path = next_scene

	transition_active = true

	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()

	var screen_pos: Vector2

	if camera:
		var canvas_transform = get_viewport().get_canvas_transform()
		screen_pos = canvas_transform * start_pos
		screen_pos.x /= viewport_size.x
		screen_pos.y /= viewport_size.y
	else:
		screen_pos = Vector2(0.5, 0.5)

	circle_shader_material.set_shader_parameter("circle_position", screen_pos)

	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)

	circle_shader_material.set_shader_parameter("circle_size", 1.5)

	tween.tween_method(
		func(value): circle_shader_material.set_shader_parameter("circle_size", value),
		1.5,
		0.0,
		2.5
	)

	tween.tween_callback(func():
		transition_halfway.emit()
		_handle_scene_switch()
	)

	tween.tween_interval(0.5)

	tween.tween_callback(func():
		await get_tree().process_frame
		_update_player_after_scene_change()
)
	tween.tween_method(
		func(value): circle_shader_material.set_shader_parameter("circle_size", value),
		0.0,
		2.0,
		2.5
	)

	tween.tween_callback(func():
		transition_active = false
		transition_complete.emit()
	)


func _handle_scene_switch():
	if next_scene_path == "":
		return
	
	var packed_scene = load(next_scene_path)
	if packed_scene:
		get_tree().change_scene_to_packed(packed_scene)


func _update_player_after_scene_change():
	var viewport_size = get_viewport().get_visible_rect().size
	var camera = get_viewport().get_camera_2d()

	var player = null

	if get_tree().get_first_node_in_group("player"):
		player = get_tree().get_first_node_in_group("player")
	elif get_tree().current_scene.has_node("player"):
		player = get_tree().current_scene.get_node("player")

	var final_pos: Vector2

	if player and player is Node2D:
		var canvas_transform = get_viewport().get_canvas_transform()
		var screen_pos = canvas_transform * player.global_position
		screen_pos.x /= viewport_size.x
		screen_pos.y /= viewport_size.y
		final_pos = screen_pos
	else:
		final_pos = Vector2(0.5, 0.5)

	circle_shader_material.set_shader_parameter("circle_position", final_pos)
