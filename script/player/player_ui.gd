extends CanvasLayer
class_name PlayerUI

@export var player: Player

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var dash: TextureProgressBar = $Dash

@onready var icon_puppet_shooter: Sprite2D = $IconPuppetShooter
@onready var icon_wolf: Sprite2D = $IconWolf
@onready var icon_puppet_shooter_2: Sprite2D = $IconPuppetShooter2
@onready var icon_puppet: Sprite2D = $IconPuppet

@onready var super_dash_indicator: AnimatedSprite2D = $SuperDashIndicator
@onready var pin_label: Label = $PinLabel
@onready var health_bar_label: Label = $HealthBar/HealthBarLabel

var health_manager: HealthManager
var dash_manager: DashManager
var skill_manager: SkillManager
var super_dash: SuperDash 
var pin: Pin 

var skill_icons: Dictionary = {}
var skill_icon_original_pos_y: Dictionary = {}
const SKILL_ICON_JUMP_HEIGHT = -20.0 


func _ready():
	health_bar_label.text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
	
	if not player:
		set_process(false) 
		return
		
	health_manager = player.health_manager
	dash_manager = player.dash_manager
	skill_manager = player.skill_manager
	super_dash = player.super_dash 
	pin = player.pin 

	if health_manager:
		health_manager.health_changed.connect(_on_health_changed)
		_on_health_changed(health_manager.current_health, health_manager.max_health)
	
	if skill_manager:
		skill_manager.stolen_skill_used.connect(_on_stolen_skill_used)
		
	if pin:
		pin.pin_count_changed.connect(_on_pin_count_changed)
		_on_pin_count_changed(pin.current_pins, pin.max_pins)
	
	_setup_morph_icons()
	
	if super_dash_indicator:
		super_dash_indicator.frame = 0 


func _process(_delta):
	if dash_manager:
		_update_dash_bar()
	
	if skill_manager:
		_update_morph_skill_icons()

	if super_dash: 
		_update_super_dash_indicator()


func _on_health_changed(current: float, max: float):
	if health_bar:
		health_bar.max_value = max
		health_bar.value = current


func _update_dash_bar():
	if not dash:
		return

	if dash_manager.weak_exit_lock_timer > 0.0:
		var cooldown_total = dash_manager.WEAK_EXIT_LOCK_TIME
		var cooldown_left = dash_manager.weak_exit_lock_timer
		var progress = (cooldown_total - cooldown_left) / cooldown_total 
		dash.value = progress * dash.max_value
		
		dash.tint_progress = Color.RED
	
	else:
		dash.tint_progress = Color.WHITE
		
		var max_charges = dash_manager.dash_count_max
		var current_charges = max_charges - dash_manager.dash_counter

		if current_charges == max_charges:
			dash.value = dash.max_value
		elif dash_manager.cooldown_timer > 0.0:
			var cooldown_total = dash_manager.COOLDOWN
			var cooldown_left = dash_manager.cooldown_timer
			var progress = (cooldown_total - cooldown_left) / cooldown_total 
			dash.value = progress * dash.max_value
		else:
			dash.value = dash.max_value



func _setup_morph_icons():
	skill_icons = {
		"homing": icon_puppet_shooter,       
		"triple_homing": icon_puppet_shooter_2, 
		"wolf": icon_wolf,                 
		"slash": icon_puppet              
	}
	
	for icon_node in skill_icons.values():
		if icon_node:
			skill_icon_original_pos_y[icon_node] = icon_node.position.y
			icon_node.visible = false

func _update_morph_skill_icons():
	for skill_name in skill_icons.keys():
		var icon_node: Sprite2D = skill_icons[skill_name]
		if not icon_node:
			continue

		var is_ready = false
		if skill_name == "homing":
			is_ready = skill_manager.homing_shot_ready
		elif skill_name == "triple_homing":
			is_ready = skill_manager.triple_homing_shot_ready
		elif skill_name == "wolf":
			is_ready = skill_manager.wolf_morph_ready
		elif skill_name == "slash":
			is_ready = skill_manager.slash_shot_ready

		var is_visible = icon_node.visible

		if is_ready and not is_visible:
			icon_node.visible = true
			_play_jump_tween(icon_node)
		elif not is_ready and is_visible:
			icon_node.visible = false

func _on_stolen_skill_used():
	pass


func _play_jump_tween(icon_node: Sprite2D):
	if not skill_icon_original_pos_y.has(icon_node):
		return 

	var original_y = skill_icon_original_pos_y[icon_node]
	
	icon_node.position.y = original_y
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT) 
	tween.set_trans(Tween.TRANS_QUAD)
	
	tween.tween_property(icon_node, "position:y", original_y + SKILL_ICON_JUMP_HEIGHT, 0.15)
	
	tween.chain()
	tween.set_ease(Tween.EASE_IN) 
	tween.tween_property(icon_node, "position:y", original_y, 0.15)


func _on_pin_count_changed(current: int, max: int):
	if pin_label:
		pin_label.text = "%d/%d" % [current, max]


func _update_super_dash_indicator():
	if not super_dash_indicator:
		return
	
	var is_ready = (super_dash.super_dash_counter == 0)
	
	var target_frame = 0
	

	var current_charge = super_dash.super_dash_recharge_counter
	if current_charge == 3:
		target_frame = 3
	elif current_charge == 2:
		target_frame = 2 
	elif current_charge == 1:
		target_frame = 1 
	else:
		target_frame = 0 
	if super_dash_indicator.frame != target_frame:
		super_dash_indicator.frame = target_frame


	


func _on_health_bar_changed() -> void:
	health_bar_label.text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))


func _on_health_bar_value_changed(value: float) -> void:
	health_bar_label.text = str(int(health_bar.value)) + "/" + str(int(health_bar.max_value))
