extends CharacterBody2D
class_name Geppetto

@export var move_speed: float = 10.0
@export var path_update_rate: float = 0.25 
@export var body_radius: float = 16.0 
@export var personal_space: float = 70.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_move_direction := Vector2.DOWN
var is_attacking := false 

@export var puppet_scene: PackedScene 
@export var wolf_scene: PackedScene
@export var flying_puppet: PackedScene
@export var dash_flying_puppet: PackedScene
@export var scissor_scene: PackedScene
@export var hammer_range: float = 200.0
@export var hammer_offset: float = 150.0 

@export var hammer_windup_time: float = 1.2
@export var hammer_damage_time: float = 0.6     
@export var hammer_recovery_time: float = 0.8

@export var swing_offset: float = 100.0 
@export var swing_phase1_windup: float = 1.0     
@export var swing_phase1_damage_time: float = 0.6
@export var swing_phase2_windup: float = 1.0   
@export var swing_phase2_damage_time: float = 0.6
@export var swing_recovery_time: float = 0.6

@export var indicator_color_windup: Color = Color(0.2, 0.5, 1.0, 0.7)
@export var indicator_color_damage: Color = Color(1.0, 0.15, 0.0, 0.7)

@export var hammer_damage: float = 25.0
@export var swing_damage: float = 20.0

@onready var stats: Stats = $Stats
@onready var attack_timer: Timer = $AttackIntervalTimer
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var hammer_indicator: Polygon2D = $HammerIndicator
@onready var health_bar: ProgressBar = $HealthBar
@export var puppet_container: Node2D
@export var spawn_container: Node2D
@export var swing_indicator_node: Node2D
@export var player_target: CharacterBody2D

enum State { MOVING, ATTACKING }
var state: State = State.MOVING

var attack_pattern_index := 0
var spawn_points = []
var attack_sequence = []
var path_update_timer := 0.0

const ISO_SCALE = Vector2(1.0, 0.5)

func _ready():
	AudioManager.change_bgm_to_combat()
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health

	if is_instance_valid(spawn_container):
		spawn_points = spawn_container.get_children()
		
	nav_agent.radius = body_radius
	nav_agent.simplify_path = true
	nav_agent.target_desired_distance = personal_space 
	nav_agent.path_desired_distance = 8.0
	nav_agent.avoidance_enabled = true
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	call_deferred("_setup_navigation")
	hammer_indicator.hide()
	nav_agent.velocity_computed.connect(_on_nav_agent_velocity_computed)

func _setup_navigation():
	await get_tree().physics_frame
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _update_target_position():
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _physics_process(delta):
	path_update_timer += delta
	if path_update_timer >= path_update_rate:
		path_update_timer = 0.0
		_update_target_position()

	match state:
		State.MOVING:
			_state_chase(delta)
		State.ATTACKING:
			_state_attack(delta)
			
	_update_animation_state() 
	move_and_slide()

func _state_chase(delta):
	if not is_instance_valid(player_target):
		nav_agent.set_velocity(Vector2.ZERO) 
		return
	var distance_to_player = global_position.distance_to(player_target.global_position)
	var target_velocity := Vector2.ZERO
	
	if distance_to_player > personal_space and not nav_agent.is_navigation_finished():
		var next_pos := nav_agent.get_next_path_position()
		var dir := (next_pos - global_position).normalized()
		target_velocity = dir * move_speed
		
	var requested_velocity := velocity.lerp(target_velocity, 8.0 * delta)
	nav_agent.set_velocity(requested_velocity)

func _state_attack(delta):
	velocity = Vector2.ZERO
	nav_agent.set_velocity(Vector2.ZERO)

func _on_attack_timer_timeout():
	if state == State.ATTACKING:
		return
		
	state = State.ATTACKING 
	nav_agent.avoidance_enabled = false
	
	if is_instance_valid(player_target):
		last_move_direction = global_position.direction_to(player_target.global_position)
	
	if attack_sequence.is_empty():
		attack_pattern_index = 0
	else:
		attack_pattern_index = attack_sequence.pop_front()
		
	match attack_pattern_index:
		0:
			_perform_spawn_puppets()
		1:
			_perform_hammer_attack()
		2:
			_perform_scissor_attack()
		3: 
			_perform_swing_attack()

func _create_random_attack_sequence():
	attack_sequence = [1, 2, 3]
	attack_sequence.shuffle()

func _perform_spawn_puppets():
	is_attacking = true
	var puppet_count = puppet_container.get_child_count()
	if puppet_count >= 4:
		_create_random_attack_sequence()
		_setup_next_attack()
		return
	
	attack_pattern_index = 0 
	_update_animation_state() 
	
	await animated_sprite.animation_finished
	
	var puppet_types = []
	if puppet_scene: puppet_types.append(puppet_scene)
	if flying_puppet: puppet_types.append(flying_puppet)
	if dash_flying_puppet: puppet_types.append(dash_flying_puppet)
	if wolf_scene: puppet_types.append(wolf_scene)
	
	if puppet_types.is_empty():
		_create_random_attack_sequence()
		_skip_attack()
		return
	
	var all_points = spawn_container.get_children()
	all_points.shuffle()
	var picked_points = all_points.slice(0, 2)
	
	for spawn_point in picked_points:
		var chosen_scene: PackedScene = puppet_types.pick_random()
		var puppet = chosen_scene.instantiate()
		puppet_container.add_child(puppet, true)
		puppet.global_position = spawn_point.global_position
	
	_create_random_attack_sequence()
	_setup_next_attack()

func _perform_hammer_attack():
	if not is_instance_valid(player_target):
		_skip_attack()
		return

	var dist = global_position.distance_to(player_target.global_position)
	if dist > hammer_range:
		_skip_attack()
		return
		
	is_attacking = true
	attack_pattern_index = 1
	_update_animation_state()
	
	var dir = global_position.direction_to(player_target.global_position)
	var impact_pos = global_position + dir * hammer_offset
	hammer_indicator.global_position = impact_pos
	hammer_indicator.begin_telegraph(indicator_color_windup)
	
	await _telegraph_wait(hammer_windup_time, hammer_damage_time, func():
		hammer_indicator.activate_damage(indicator_color_damage, hammer_damage)
	)
	
	if not is_inside_tree(): return
	await get_tree().create_timer(hammer_recovery_time).timeout
	if not is_inside_tree(): return
		
	_setup_next_attack()

func _telegraph_wait(total: float, damage_at: float, damage_cb: Callable) -> void:
	var elapsed := 0.0
	var done := false
	while elapsed < total:
		if not is_inside_tree(): return
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if not done and elapsed >= damage_at:
			if damage_cb:
				damage_cb.call()
			done = true

func _perform_scissor_attack():
	is_attacking = true
	attack_pattern_index = 2 
	_update_animation_state()
	
	await animated_sprite.animation_finished

	if scissor_scene:
		var scissor = scissor_scene.instantiate()
		get_parent().add_child(scissor)
		scissor.global_position = global_position + Vector2(0, -50)
	
	_setup_next_attack()

func _perform_swing_attack():
	if not is_instance_valid(player_target) or not swing_indicator_node:
		_skip_attack()
		return

	is_attacking = true 

	var top_area = swing_indicator_node.get_node("Top")
	var mid_area = swing_indicator_node.get_node("Mid")
	var bottom_area = swing_indicator_node.get_node("Bottom")
	
	var dir_to_player = global_position.direction_to(player_target.global_position)
	var raw_angle = dir_to_player.angle()
	var step = PI / 4.0 
	var snapped_angle = round(raw_angle / step) * step
	last_move_direction = Vector2.RIGHT.rotated(snapped_angle)
	swing_indicator_node.rotation = 0
	swing_indicator_node.global_position = global_position 
	
	var swing_length = 220.0
	var swing_width = 70.0
	var start_offset = 40.0
	var lane_spacing = 80.0 
	
	attack_pattern_index = 3 
	_update_animation_state()
	
	if top_area.has_method("build_rectangle_iso"):
		top_area.build_rectangle_iso(swing_length, swing_width, snapped_angle, start_offset, -lane_spacing)
	if bottom_area.has_method("build_rectangle_iso"):
		bottom_area.build_rectangle_iso(swing_length, swing_width, snapped_angle, start_offset, lane_spacing)
	
	if top_area.has_method("begin_telegraph"): top_area.begin_telegraph(indicator_color_windup)
	if bottom_area.has_method("begin_telegraph"): bottom_area.begin_telegraph(indicator_color_windup)
		
	await _telegraph_wait(swing_phase1_windup, swing_phase1_damage_time, func():
		if top_area.has_method("activate_damage"): top_area.activate_damage(indicator_color_damage, swing_damage)
		if bottom_area.has_method("activate_damage"): bottom_area.activate_damage(indicator_color_damage, swing_damage)
	)
	
	if not is_inside_tree(): return
	await get_tree().create_timer(0.2).timeout 

	attack_pattern_index = 1 
	_update_animation_state() 
	
	if mid_area.has_method("build_rectangle_iso"):
		mid_area.build_rectangle_iso(swing_length * 1.1, swing_width * 1.8, snapped_angle, start_offset, 0.0)
	if mid_area.has_method("begin_telegraph"):
		mid_area.begin_telegraph(indicator_color_windup)
		
	await _telegraph_wait(swing_phase2_windup, swing_phase2_damage_time, func():
		if mid_area.has_method("activate_damage"): mid_area.activate_damage(indicator_color_damage, swing_damage)
	)
	
	if not is_inside_tree(): return
	await get_tree().create_timer(swing_recovery_time).timeout
	if not is_inside_tree(): return
	
	_setup_next_attack()

func _on_nav_agent_velocity_computed(safe_velocity: Vector2):
	if state == State.ATTACKING:
		velocity = Vector2.ZERO
		return
	velocity = safe_velocity
	

func _setup_next_attack():
	is_attacking = false 
	state = State.MOVING 
	nav_agent.avoidance_enabled = true
	attack_timer.start()
	
func _skip_attack():
	is_attacking = false 
	state = State.MOVING
	nav_agent.avoidance_enabled = true
	attack_timer.start()

func _get_direction_suffix(direction: Vector2) -> String:
	var angle = direction.angle()
	if abs(angle) <= PI / 8.0: return "E"
	elif angle > PI / 8.0 and angle <= 3.0 * PI / 8.0: return "SE"
	elif angle > 3.0 * PI / 8.0 and angle <= 5.0 * PI / 8.0: return "S"
	elif angle > 5.0 * PI / 8.0 and angle <= 7.0 * PI / 8.0: return "SW"
	elif abs(angle) > 7.0 * PI / 8.0: return "W"
	elif angle < -5.0 * PI / 8.0 and angle >= -7.0 * PI / 8.0: return "NW"
	elif angle < -3.0 * PI / 8.0 and angle >= -5.0 * PI / 8.0: return "N"
	elif angle < -PI / 8.0 and angle >= -3.0 * PI / 8.0: return "NE"
	return "S"
	
func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	var suffix := _get_direction_suffix(direction)
	var anim_name = "%s_%s" % [prefix, suffix]
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "%s_S" % prefix 
		if not animated_sprite.sprite_frames.has_animation(anim_name):
			return
	
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)

func _update_animation_state() -> void:
	var anim_prefix = "IDLE"
	var anim_direction = last_move_direction

	if is_attacking:
		match attack_pattern_index:
			0: anim_prefix = "SUMMON"
			1: anim_prefix = "ATTACK_SLAM"
			2: anim_prefix = "SUMMON"
			3: anim_prefix = "SWING"
			_: anim_prefix = "IDLE"
				
	elif velocity.length() > 1.0:
		anim_prefix = "WALK"
		anim_direction = velocity.normalized()
		last_move_direction = anim_direction

	_play_directional_animation(anim_prefix, anim_direction)
