extends CharacterBody2D
class_name Geppetto
# --- Variabel Gerakan & Animasi ---
@export var move_speed: float = 10.0
@export var path_update_rate: float = 0.25 
@export var body_radius: float = 16.0 
@export var personal_space: float = 70.0 

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
var last_move_direction := Vector2.DOWN
var is_attacking: bool = false # (Flag untuk animasi)

# --- Variabel Serangan ---
@export var puppet_scene: PackedScene 
@export var wolf_scene: PackedScene
@export var flying_puppet: PackedScene
@export var dash_flying_puppet: PackedScene
@export var hammer_aoe_scene: PackedScene
@export var scissor_scene: PackedScene
@export var hammer_range: float = 200.0
@export var hammer_offset: float = 150.0 # (Dari chat sebelumnya)

@onready var stats: Stats = $Stats
@onready var attack_timer: Timer = $AttackIntervalTimer
@onready var nav_agent: NavigationAgent2D = $NavAgent
@onready var hammer_indicator: Polygon2D = $HammerIndicator
@onready var health_bar: ProgressBar = $HealthBar
@export var puppet_container: Node2D
@export var spawn_container: Node2D
@export var swing_indicator: Node2D
@export var player_target: CharacterBody2D
enum State { MOVING, ATTACKING }
var state: State = State.MOVING # (Mulai di MOVING)
var attack_pattern_index: int = 0
var spawn_points = []
var attack_sequence = []
var path_update_timer: float = 0.0
var override_anim_name: String = "" 
const ISO_SCALE = Vector2(1.0, 0.5)
func _ready():
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	if (is_instance_valid(spawn_container)):
		spawn_points = spawn_container.get_children()
		
	nav_agent.radius = body_radius
	nav_agent.simplify_path = true
	nav_agent.target_desired_distance = personal_space
	nav_agent.path_desired_distance = 8.0
	
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	call_deferred("_setup_navigation")
	
	hammer_indicator.hide()
	
	# --- [BARU] Hubungkan sinyal animasi ---
	animated_sprite.animation_finished.connect(_on_animation_finished)
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
			
	_update_animation_state() # <-- [BARU] Panggil update animasi
	move_and_slide()

func _state_chase(delta):
# (Animasi "WALK" akan di-handle oleh _update_animation_state)
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
# Jangan 'await' di sini. Fungsi ini hanya memilih serangan.
	
	# 1. Jika kita masih menyerang, jangan lakukan apa-apa
	if state == State.ATTACKING:
		return
		
	# 2. Set state ke ATTACKING (berhenti bergerak)
	state = State.ATTACKING 
	
	# 3. Tentukan arah serangan (untuk animasi)
	if is_instance_valid(player_target):
		last_move_direction = global_position.direction_to(player_target.global_position)
	
	var attack_to_perform = attack_pattern_index
	
	# 4. Tentukan serangan BERIKUTNYA
	if (attack_sequence.size() < 1):
		attack_pattern_index = 0
	else:
		attack_pattern_index = attack_sequence.pop_front()
		
	# 5. Jalankan serangan SAAT INI
	match attack_to_perform:
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
	
func _check_for_emergency_spawn():
	if attack_timer.time_left < 1.0: 
		
		var puppet_count = puppet_container.get_child_count()
		var player_node = player_target as Player
		if player_node and player_node.possession_manager.is_possessing:
			puppet_count += 1
			
		if puppet_count == 0:
			state = State.ATTACKING
			attack_timer.stop() # Hentikan timer normal
			_perform_spawn_puppets() # Panggil spawn darurat
func _perform_spawn_puppets():
	print("skill 1: spawn puppet (random type)")
	
	# 1. Mainkan animasi "SUMMON"
	is_attacking = true
	_update_animation_state() # (Akan memutar animasi SUMMON)
	
	await get_tree().create_timer(0.5).timeout
	
	var puppet_count = puppet_container.get_child_count()
	if (puppet_count >= 4):
		print("Spawn skip, terlalu banyak puppet.")
		_skip_attack()
		return
	
	# --- PILIH RANDOM DARI 4 JENIS MOB ---
	var puppet_types = []
	if puppet_scene: puppet_types.append(puppet_scene)
	if flying_puppet: puppet_types.append(flying_puppet)
	if dash_flying_puppet: puppet_types.append(dash_flying_puppet)
	if wolf_scene: puppet_types.append(wolf_scene)
	
	if puppet_types.is_empty():
		print("ERROR: Tidak ada puppet yang tersedia untuk di-spawn.")
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
	
	await animated_sprite.animation_finished 
	_create_random_attack_sequence() 
	attack_pattern_index = attack_sequence.pop_front() 
	_setup_next_attack()


func _perform_hammer_attack():
	print("skill 2: hammer")
	
	if not is_instance_valid(player_target):
		_skip_attack()
		return
		
	var distance_to_player = global_position.distance_to(player_target.global_position)
	
	if distance_to_player <= hammer_range:
		# Player cukup dekat, serang!
		var direction_to_player = global_position.direction_to(player_target.global_position)
		var target_pos = global_position + direction_to_player * hammer_offset
		
		# 1. Tampilkan Indikator
		hammer_indicator.global_position = target_pos
		hammer_indicator.rotation = direction_to_player.angle()
		hammer_indicator.show()
		await get_tree().create_timer(1.5).timeout
		
		# 2. Mainkan Animasi "ATTACK_SLAM"
		is_attacking = true
		_update_animation_state() # (Akan memutar "ATTACK_SLAM_...")
		
		hammer_indicator.color = Color.BLUE
		await get_tree().create_timer(0.5).timeout # (Waktu untuk animasi)
		hammer_indicator.hide()
		
		# 3. Spawn Hitbox
		if hammer_aoe_scene:
			var hitbox = hammer_aoe_scene.instantiate()
			get_parent().add_child(hitbox)
			hitbox.global_position = target_pos
		
		# 4. Tunggu sisa animasi & cooldown
		await get_tree().create_timer(1.5).timeout # (Sisa 2.0 detik - 0.5)
		_setup_next_attack()
		
	else:
		print("hammer skip, too far.")
		_skip_attack()
func _perform_scissor_attack():
	print("skill 3: scissor")
	
	# 1. Mainkan animasi "SPAWN" (sama seperti spawn puppet)
	is_attacking = true
	_update_animation_state() # (Akan memutar "SPAWN_...")
	
	# 2. Tunggu 0.5 detik
	await get_tree().create_timer(0.5).timeout
	
	# 3. Spawn Gunting
	if scissor_scene:
		var scissor = scissor_scene.instantiate()
		get_parent().add_child(scissor)
		scissor.global_position = global_position + Vector2(0, -50) 
	
	# 4. Tunggu sisa animasi
	await animated_sprite.animation_finished
	
	# 5. Selesai
	_setup_next_attack()
func _perform_swing_attack():
	print("skill 4: swing")
	var top_area = swing_indicator.get_node("Top")
	var mid_area = swing_indicator.get_node("Mid")
	var bottom_area = swing_indicator.get_node("Bottom")
	
	# --- SERANGAN 1 (SISI) ---
	top_area.color = Color.RED
	bottom_area.color = Color.RED
	top_area.show()
	bottom_area.show()
	await get_tree().create_timer(1.5).timeout
	
	# 1a. Mainkan animasi "SWING"
	is_attacking = true
	attack_pattern_index = 3
	_update_animation_state()
	await animated_sprite.animation_finished
	
	top_area.hide()
	bottom_area.hide()
	
	# --- SERANGAN 2 (TENGAH) ---
	mid_area.color = Color.RED
	mid_area.show()
	await get_tree().create_timer(1.5).timeout
	
	# 2a. Mainkan animasi "SLAM" setelah swing
	is_attacking = true
	attack_pattern_index = 1 # supaya animasi jadi SLAM
	_update_animation_state()
	
	mid_area.color = Color.BLUE
	await animated_sprite.animation_finished
	mid_area.hide()
	
	_setup_next_attack()

	
func _setup_next_attack():
	state = State.MOVING 
	attack_timer.start()
	
func _skip_attack():
	print("attack skipped, next att")
	state = State.MOVING
	attack_timer.start()
func _get_direction_suffix(direction: Vector2) -> String:
	var angle = direction.angle()
	
	if abs(angle) <= PI / 8.0:
		return "E"
	elif angle > PI / 8.0 and angle <= 3.0 * PI / 8.0:
		return "SE"
	elif angle > 3.0 * PI / 8.0 and angle <= 5.0 * PI / 8.0:
		return "S"
	elif angle > 5.0 * PI / 8.0 and angle <= 7.0 * PI / 8.0:
		return "SW"
	elif abs(angle) > 7.0 * PI / 8.0:
		return "W"
	elif angle < -5.0 * PI / 8.0 and angle >= -7.0 * PI / 8.0:
		return "NW"
	elif angle < -3.0 * PI / 8.0 and angle >= -5.0 * PI / 8.0:
		return "N"
	elif angle < -PI / 8.0 and angle >= -3.0 * PI / 8.0:
		return "NE"
	
	return "S" # Fallback default
	
func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	var suffix := _get_direction_suffix(direction)
	var anim_name = "%s_%s" % [prefix, suffix]
	
	if not animated_sprite.sprite_frames.has_animation(anim_name):
		anim_name = "%s_S" % prefix # Fallback ke Selatan
		if not animated_sprite.sprite_frames.has_animation(anim_name):
			print("ERROR: Animasi %s_S tidak ditemukan!" % prefix)
			return
	
	if animated_sprite.animation != anim_name or not animated_sprite.is_playing():
		animated_sprite.play(anim_name)
func _update_animation_state() -> void:
	var anim_prefix = "IDLE"
	var anim_direction = last_move_direction

	if is_attacking:
		match attack_pattern_index:
			0: # Spawn (summon puppet)
				anim_prefix = "SUMMON"
			1: # Hammer
				anim_prefix = "ATTACK_SLAM"
			2: # Scissor
				anim_prefix = "SUMMON"
			3: # Swing
				anim_prefix = "SWING"
			_: 
				anim_prefix = "ATTACK_SLAM"
	elif velocity.length() > 1.0:
		anim_prefix = "WALK"
		anim_direction = velocity.normalized()
		last_move_direction = anim_direction

	_play_directional_animation(anim_prefix, anim_direction)

func _on_animation_finished() -> void:
	if is_attacking:
		is_attacking = false # Reset flag
