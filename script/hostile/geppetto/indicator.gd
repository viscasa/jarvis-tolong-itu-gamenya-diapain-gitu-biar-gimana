@tool
extends Polygon2D

@export var radius: float = 128.0
@export var iso_y_scale: float = 0.5
@export var sides: int = 64
@export var damage: float = 25.0
@export var active_time: float = 0.15
@export var lifetime_after_active: float = 0.20
@export var rotation_offset: float = 0.0
@export var shake_intensity: float = 18.0
@export var shake_duration: float = 0.6
@export_flags_2d_physics var hit_mask: int = 0xFFFFFFFF 

var _area: Area2D
var _shape: CollisionShape2D
var _applied := false
var _active := false

func _ready():
	_rebuild()
	_setup_area()

func _rebuild():
	var pts: PackedVector2Array = []
	for i in range(sides):
		var ang = i * TAU / sides
		var local_x = cos(ang) * radius
		var local_y = sin(ang) * radius
		pass

func build_rectangle_iso(length: float, width: float, direction_angle: float, start_offset: float = 0.0, side_offset: float = 0.0):
	var pts: PackedVector2Array = []
	var corners = [
		Vector2(start_offset, -width/2 + side_offset),
		Vector2(start_offset + length, -width/2 + side_offset),
		Vector2(start_offset + length, width/2 + side_offset),
		Vector2(start_offset, width/2 + side_offset)
	]
	for p in corners:
		var rotated_p = p.rotated(direction_angle)
		var iso_p = Vector2(rotated_p.x, rotated_p.y * iso_y_scale)
		pts.append(iso_p)
	polygon = pts
	_update_collision_polygon(pts)

func _update_collision_polygon(pts: PackedVector2Array):
	if not _shape: return
	if not _shape.shape is ConvexPolygonShape2D:
		var new_shape = ConvexPolygonShape2D.new()
		_shape.shape = new_shape
	_shape.shape.points = pts
	_shape.scale = Vector2.ONE

func _setup_area():
	if _area: return
	_area = Area2D.new()
	_shape = CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	_shape.shape = circle
	_shape.scale = Vector2(1.0, iso_y_scale)
	add_child(_area)
	_area.add_child(_shape)
	_area.collision_layer = 0 
	_area.collision_mask = hit_mask 
	_area.monitoring = false
	_area.monitorable = true
	_shape.disabled = true
	_area.body_entered.connect(_on_body_entered)

func set_indicator_color(col: Color):
	color = col

func begin_telegraph(windup_color: Color):
	set_indicator_color(windup_color)
	_applied = false
	_active = false
	if _area:
		_area.monitoring = false
		_shape.disabled = true
	show()

func activate_damage(damage_color: Color, damage_value: float = -1.0):
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("apply_shake"):
		camera.apply_shake(shake_intensity, shake_duration)
	if damage_value > 0.0:
		damage = damage_value
	set_indicator_color(damage_color)
	_active = true
	if _area:
		_area.monitoring = true
		_shape.disabled = false
		_area.collision_mask = hit_mask 
	_apply_initial_overlaps()
	await get_tree().physics_frame
	if not _applied:
		_apply_initial_overlaps()
	_call_deactivate()

func _apply_initial_overlaps():
	if not _active or _applied or not _area: return
	var bodies = _area.get_overlapping_bodies()
	for b in bodies:
		_apply_damage_if_player(b)
		if _applied:
			break

func _call_deactivate():
	await get_tree().create_timer(active_time).timeout
	if _shape: _shape.disabled = true
	if _area: _area.monitoring = false
	await get_tree().create_timer(lifetime_after_active).timeout
	if self:
		hide()
	_active = false

func _on_body_entered(body: Node):
	if _applied or not _active:
		return
	_apply_damage_if_player(body)

func _apply_damage_if_player(body: Node):
	if _applied: return
	if body is Player:
		var hm = body.health_manager
		if hm and hm.has_method("take_damage"):
			var dir = (body.global_position - global_position).normalized()
			hm.take_damage(damage, 1.0, true, dir * 2)
			_applied = true
