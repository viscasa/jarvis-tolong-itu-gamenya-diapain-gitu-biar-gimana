extends CharacterBody2D
class_name Geppetto
@onready var stats: Stats = $Stats
@onready var attack_timer: Timer = $AttackIntervalTimer
@onready var nav_agent: NavigationAgent2D = $NavAgent
@export var move_speed: float = 10.0
@export var path_update_rate: float = 0.25 
@export var puppet_scene: PackedScene 
@export var hammer_aoe_scene: PackedScene
@export var scissor_scene: PackedScene
@export var hammer_range: float = 200.0
@export var puppet_container: Node2D
@export var spawn_container: Node2D
@export var swing_indicator: Node2D
@export var player_target: CharacterBody2D
@onready var hammer_indicator: Polygon2D = $HammerIndicator
enum State { MOVING, ATTACKING }
var state: State = State.ATTACKING
var attack_pattern_index: int = 0
var spawn_points = []
var attack_sequence = []
var path_update_timer: float = 0.0
func _ready():
	if (is_instance_valid(spawn_container)):
		spawn_points = spawn_container.get_children()
		
	nav_agent.simplify_path = true
	nav_agent.path_desired_distance = 8.0
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	call_deferred("_setup_navigation")
func _setup_navigation():
	await get_tree().physics_frame
	if is_instance_valid(player_target):
		nav_agent.target_position = player_target.global_position

func _update_target_position():
	if is_instance_valid(player_target):
		var distance_to_target = player_target.global_position.distance_to(nav_agent.target_position)
		if distance_to_target > 20.0 or not nav_agent.is_target_reachable():
			nav_agent.target_position = player_target.global_position

func _physics_process(delta):
	path_update_timer += delta
	if path_update_timer >= path_update_rate:
		path_update_timer = 0.0
		_update_target_position()

	match state:
		State.MOVING:
			_state_chase(delta)
			_check_for_emergency_spawn()
		State.ATTACKING:
			_state_attack(delta)
	move_and_slide()
	
	
	if stats.current_health < stats.max_health * 0.5:
		attack_timer.wait_time = 2.0 
	else:
		attack_timer.wait_time = 4.0

func _state_chase(delta):
	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
		return
	
	if nav_agent.is_navigation_finished():
		velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
		return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	var target_velocity = direction * move_speed
	velocity = velocity.lerp(target_velocity, 8.0 * delta) 
	

func _state_attack(delta):
	velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta)
	
	
func _on_attack_timer_timeout():
	state = State.ATTACKING 
	var attack_to_perform = attack_pattern_index
	
	if (attack_sequence.size() < 1):
		attack_pattern_index = 0
	else:
		attack_pattern_index = attack_sequence.pop_front() 
	if attack_to_perform == 0:
		_perform_spawn_puppets()
	elif attack_to_perform == 1:
		_perform_hammer_attack()
	elif attack_to_perform == 2:
		_perform_scissor_attack()
	else: 
		_perform_swing_attack()

func _create_random_attack_sequence():
	attack_sequence = [1, 2, 3]
	attack_sequence.shuffle()
	
func _check_for_emergency_spawn():
	if attack_timer.time_left < 1.0: 
		var puppet_count = puppet_container.get_child_count()
		var player_node = player_target as Player
		if puppet_count == 0:
			state = State.ATTACKING
			_perform_spawn_puppets()

func _perform_spawn_puppets():
	# spawn puppet, teriak or something selama spawning (maybe 2s), skip kalo kebanyakan
	print("skill 1: spawn puppet")
	var puppet_count = puppet_container.get_child_count()
	if (puppet_count >= 4):
		_skip_attack()
	var points = spawn_points
	
	var all_points = spawn_container.get_children()
	all_points.shuffle()
	
	var picked_points = all_points.slice(0, 3) 
	
	for spawn_point in picked_points:
		if puppet_scene:
			var puppet = puppet_scene.instantiate()
			puppet_container.add_child(puppet) 
			puppet.global_position = spawn_point.global_position

	_create_random_attack_sequence() 
	attack_pattern_index = attack_sequence.pop_front() 
	await get_tree().create_timer(2.0).timeout
	_setup_next_attack()


func _perform_hammer_attack():
	# mukul hammer ke arah player, jika terlalu jauh skip att ini. show indicator 1.5 detik lalu baru mainkan animasi hammer sekitar 2 detik
	print("skill 2: hammer")
	hammer_indicator.color = Color.RED
	if not is_instance_valid(player_target):
		_skip_attack()
		return
		
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if distance_to_player <= hammer_range:
		var direction_to_player = global_position.direction_to(player_target.global_position)
		var target_pos = global_position + direction_to_player * Vector2(100, 100)
		
		hammer_indicator.global_position = target_pos
		hammer_indicator.show()
		
		await get_tree().create_timer(1.5).timeout
		hammer_indicator.color = Color.BLUE
		await get_tree().create_timer(2.0).timeout
		hammer_indicator.hide()
		
		if hammer_aoe_scene:
			var hitbox = hammer_aoe_scene.instantiate()
			get_parent().add_child(hitbox)
			hitbox.global_position = target_pos
		
		_setup_next_attack()
		
	else:
		print("Hammer skip, player too far.")
		_skip_attack()
	
func _perform_scissor_attack():
	print("skill 3: scissor")
	
	if scissor_scene:
		var scissor = scissor_scene.instantiate()
		get_parent().add_child(scissor)
		
		scissor.global_position = global_position + Vector2(0, -50) 
	
	await get_tree().create_timer(2.0).timeout
	
	state = State.MOVING
	attack_timer.start()
func _perform_swing_attack():
	# swing tangan kiri dan kanan, muncul indicator skill 1.5 detik lalu serang selama 1.5 detik, lalu yang ulangi tapi untuk yang mid baru nex tatt
	print("skill 4: swing")
	var top_area = swing_indicator.get_node("Top")
	var mid_area = swing_indicator.get_node("Mid")
	var bottom_area = swing_indicator.get_node("Bottom")
	top_area.color = Color.RED
	mid_area.color = Color.RED
	bottom_area.color = Color.RED
	
	top_area.show()
	bottom_area.show()
	await get_tree().create_timer(1.5).timeout
	
	top_area.color = Color.BLUE
	bottom_area.color = Color.BLUE
	await get_tree().create_timer(1.5).timeout
	
	top_area.hide()
	bottom_area.hide()
	mid_area.show()
	await get_tree().create_timer(1.5).timeout
	mid_area.color = Color.BLUE
	await get_tree().create_timer(1.5).timeout
	mid_area.hide()
	
	_setup_next_attack()
	
func _setup_next_attack():
	state = State.MOVING 
	attack_timer.start()
	
func _skip_attack():
	print("Attack skipped, setting up next attack.")
	state = State.MOVING
	attack_timer.start()
