extends Node2D
class_name Pin

@export var pin_scene: PackedScene

@export var max_pins: int = 3
@export var pin_reload_time: float = 0.1
@export var max_distance: float = 100.0
@export var pin_speed: float = 800.0

@onready var player: Player = $"../.."
@onready var dash_manager: DashManager = $"../../DashManager"
@onready var super_dash: SuperDash = $"../SuperDash"
@onready var homing_shot: HomingShot = $"../HomingShot"
@onready var triple_homing_shot: TripleHomingShot = $"../TripleHomingShot"
@onready var morph_skill: Node2D = $"../MorphSkill"


var current_pins: int
var reload_timer: float = 0.0
var is_throwing: bool = false

signal pin_count_changed(current_pins, max_pins)

func _ready() -> void:
	current_pins = max_pins
	emit_signal("pin_count_changed", current_pins, max_pins)

func _process(delta: float) -> void:
	if reload_timer > 0.0:
		reload_timer -= delta

func is_active() -> bool:
	return is_throwing

func throw_pin() -> void:
	if reload_timer > 0.0:
		return
	
	if current_pins <= 0:
		return
		
	if not player or not dash_manager or not super_dash or not homing_shot or not triple_homing_shot: 
		push_error("Referensi Pin.gd belum di-set oleh Player!")
		return
		
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active() or morph_skill.is_active():
		return
		
	is_throwing = true
	
	var player_pos = player.global_position
	var mouse_pos = player.get_global_mouse_position()
	
	var direction = (mouse_pos - player_pos).normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
		
	var distance_to_mouse = player_pos.distance_to(mouse_pos)
	var target_distance = min(distance_to_mouse, max_distance)
	
	current_pins -= 1
	emit_signal("pin_count_changed", current_pins, max_pins)
	if reload_timer <= 0.0 and current_pins < max_pins:
		reload_timer = pin_reload_time
		 
	if not pin_scene:
		push_error("Pin.gd: pin_scene belum di-set di Inspector!")
		is_throwing = false
		return
		
	var pin_instance = pin_scene.instantiate()
	get_parent().get_parent().get_parent().add_child(pin_instance, true)
	pin_instance.global_position = player_pos
	
	if pin_instance.has_method("launch"):
		pin_instance.launch(direction, pin_speed, target_distance)
	else:
		push_error("Instance Pin (ThrownPin.tscn) tidak punya method 'launch(direction, speed, distance)'!")
		
	is_throwing = false

func add_count() -> void:
	current_pins += 1
	emit_signal("pin_count_changed", current_pins, max_pins)
