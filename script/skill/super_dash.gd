extends Node2D
class_name SuperDash

signal super_dash_started
signal super_dash_charge_ended
signal super_dash_movement_ended 
signal rechare_counter_changed

@onready var attack_manager: AttackManager = $"../../AttackManager"
@onready var thunder: Line2D = $"../Thunder"
@onready var sprite: AnimatedSprite2D = $"../../Sprite"
@onready var ghost_timer_super_dash: Timer = $"../../GhostTimerSuperDash"
var ghost_scene = preload("res://scene/skill/dash_ghost.tscn")

const SCALE_UP = 1.7
@export var charge_time := 0.15
@export var charge_speed := 250.0 * SCALE_UP
@export var dash_speed := 1500.0 * SCALE_UP
@export var max_dash_distance := 200.0 * SCALE_UP
@export var stop_friction_factor := 0.1 * SCALE_UP
@export var aoe_radius := 50.0 * SCALE_UP
@export var aoe_damage := 50.0
@export var super_dash_max : int = 1
@export var super_dash_counter : int = 1
@export var super_dash_recharge_counter : int = 0
@export var super_dash_recharge_needed : int = 3

var player: Player
var dash_manager: DashManager

var is_charging: bool = false
var is_dashing: bool = false

var charge_timer: float = 0.0
var dash_move_timer: float = 0.0

var dash_direction := Vector2.ZERO
var charge_direction := Vector2.ZERO

var aoe_area: Area2D
var aoe_shape: CollisionShape2D

var damaged_bodies_this_dash: Array = []

func _ready() -> void:
	aoe_area = Area2D.new()
	aoe_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = aoe_radius
	aoe_shape.shape = shape
	
	aoe_area.add_child(aoe_shape)
	add_child(aoe_area)
	
	aoe_area.monitoring = false
	aoe_area.monitorable = false
	aoe_shape.disabled = true
	aoe_area.set_collision_mask_value(3, true)
	aoe_area.set_collision_mask_value(1, false)
	aoe_area.set_collision_layer_value(1, false)
	
	aoe_area.body_entered.connect(_on_aoe_body_entered)
	
	attack_manager.critical_circle.connect(_add_counter)
	super_dash_started.connect(_add_super_dash)
	rechare_counter_changed.connect(_process_recharge_counter)

func is_active() -> bool:
	return is_charging or is_dashing
func start_super_dash() -> void:
	if super_dash_counter >= super_dash_max :
		return

	if is_active() or dash_manager.is_dashing or dash_manager.is_dash_moving or dash_manager.is_exit_dashing or dash_manager.is_exit_moving:
		return

	is_charging = true
	charge_timer = charge_time
	
	dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	charge_direction = -dash_direction
	
	super_dash_recharge_counter = 0
	emit_signal("super_dash_started")

func process_super_dash(delta: float) -> void:
	if is_charging:
		charge_timer -= delta
		if charge_timer <= 0.0:
			_start_dash_movement()
	
	elif is_dashing:
		dash_move_timer -= delta
		if dash_move_timer <= 0.0:
			_end_dash_movement()

func _start_dash_movement() -> void:
	is_charging = false
	is_dashing = true
	thunder.clear_points()
	ghost_timer_super_dash.start()
	thunder.add_point(player.global_position)
	thunder.anim_vanish()
	
	if dash_speed <= 0.0:
		push_error("SuperDash dash_speed tidak boleh nol!")
		dash_move_timer = 0.0
	else:
		dash_move_timer = max_dash_distance / dash_speed
	
	dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	
	damaged_bodies_this_dash.clear()
	aoe_shape.disabled = false
	aoe_area.monitoring = true
	
	emit_signal("super_dash_charge_ended")

func _end_dash_movement() -> void:
	is_dashing = false
	dash_move_timer = 0.0 
	
	if player:
		player.velocity *= stop_friction_factor
	
	aoe_shape.disabled = true
	aoe_area.monitoring = false
	ghost_timer_super_dash.stop()
	
	emit_signal("super_dash_movement_ended")
	
	thunder.add_point(player.global_position + 0.3*(player.global_position-thunder.get_point_position(0)))
	

func get_charge_velocity() -> Vector2:
	if not is_charging:
		return Vector2.ZERO
	
	return charge_direction * charge_speed
func get_dash_velocity() -> Vector2:
	if not is_dashing:
		return Vector2.ZERO
		
	return dash_direction * dash_speed

func _on_aoe_body_entered(body) -> void:
	if not is_dashing:
		return
	if body == player:
		return
	if body in damaged_bodies_this_dash:
		return
	
	damaged_bodies_this_dash.append(body)
	
	var hit_direction = (body.global_position - global_position).normalized()
	
	attack_manager.attack(body, hit_direction, false, aoe_damage)

func _reset_super_dash_counter() :
	super_dash_counter = 0

func _add_super_dash() :
	if (super_dash_counter+1>super_dash_max) :
		return
	super_dash_counter+=1

func _process_recharge_counter() -> void :
	if super_dash_recharge_counter >= super_dash_recharge_needed :
		super_dash_counter = super_dash_max
		super_dash_recharge_counter = 0

func _add_counter() :
	if (super_dash_recharge_counter+1 > super_dash_recharge_needed) :
		return
	super_dash_recharge_counter += 1
	emit_signal("rechare_counter_changed")

func instance_ghost(color : Color = Color.WHITE) -> void :
	var ghost: Sprite2D = ghost_scene.instantiate()
	ghost.color = color
	get_tree().root.add_child(ghost)
	
	ghost.global_position = self.global_position
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)

func _on_ghost_timer_super_dash_timeout() -> void:
	instance_ghost()
