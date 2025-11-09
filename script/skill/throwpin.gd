extends CharacterBody2D
class_name ThrownPin

@onready var stats: Stats = $Stats
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_timer: Timer = $AttackTimer # Ini adalah timer "lifetime"
@onready var needle: Sprite2D = $Needle
@onready var hurtbox_collision: CollisionShape2D = $Hurtbox/CollisionShape2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var hitbox_collision: CollisionShape2D = $Hitbox/CollisionShape2D
enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 

var speed: float = 0.0
var direction: Vector2 = Vector2.ZERO
var distance_to_travel: float = 0.0
var damage: float = 10.0
var duration: float = 3 # Ini adalah lifetime total

# --- TAMBAHKAN VARIABLE BARU ---
var travel_timer: float = 0.0 # Ini adalah timer "movement"

# Fungsi ini dipanggil oleh Pin.gd
func launch(_direction: Vector2, _speed: float, _distance: float):
	direction = _direction
	speed = _speed
	distance_to_travel = _distance
	
	# --- UBAH LOGIKA LAUNCH ---
	# Hitung berapa lama waktu yang dibutuhkan untuk bergerak
	if speed > 0.0:
		travel_timer = distance_to_travel / speed
	else:
		travel_timer = 0.0
		
	# Set velocity AWAL
	velocity = direction * speed
	
	# Mulai timer LIFETIME (ini terpisah dari timer gerak)
	attack_timer.start(duration)

func _ready() -> void:
	current_state = State.ATTACK
	add_to_group("enemies")
	needle.material.set_shader_parameter('percentage', 1.0)
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	stats.no_health.connect(_on_death)

func _physics_process(delta: float) -> void:
	
	# --- LOGIKA MOVEMENT BARU ---
	if travel_timer > 0.0:
		# Jika masih ada waktu untuk bergerak
		travel_timer -= delta
		
		# Panggil move_and_slide()
		# Velocity sudah di-set di launch()
		move_and_slide()
		
		# Cek apakah baru saja menabrak sesuatu
		if get_slide_collision_count() > 0:
			_stop_movement() # Berhenti karena menabrak
		
		# Cek apakah waktu tempuh habis
		elif travel_timer <= 0.0:
			_stop_movement() # Berhenti karena jarak maks tercapai
			
	else:
		# Jika sudah berhenti, pastikan velocity 0
		velocity = Vector2.ZERO
		move_and_slide() # Panggil move_and_slide agar tetap di tempat

# --- GANTI NAMA FUNGSI ---
func _stop_movement() -> void:
	travel_timer = 0.0
	speed = 0.0 # Hentikan pergerakan
	velocity = Vector2.ZERO # Hentikan velocity

func _on_death():
	current_state = State.DEAD
	hitbox_collision.set_deferred("disabled", true)
	hurtbox_collision.set_deferred("disabled", true)
	body_collision.set_deferred("disabled", true)
	var player_nodes = get_tree().get_nodes_in_group("player")
	if not player_nodes.is_empty():
		var player = player_nodes[0]
		player.get_node("SkillManager").add_pin()
	
	set_physics_process(false)
	#$CollisionShape2D.disabled = true
	#if $Hurtbox: 
		#$Hurtbox/CollisionShape2D.disabled = true
	#
	#await animated_sprite.animation_finished
	
	# Cek jika player masih ada sebelum panggil morph
	tween_percent()

func _on_attack_timer_timeout() -> void:
	# Timer lifetime habis, panggil _on_death()
	hurtbox_collision.disabled = true
	body_collision.disabled = true
	_on_death()

func _on_hurtbox_player_auto_exit() -> void:
	attack_timer.start(duration)
	
func _on_hurtbox_player_possessed() -> void:
	attack_timer.stop()

func set_percent(percentage: float) -> void:
	needle.material.set_shader_parameter('percentage', percentage)

func tween_percent():
	var tween = create_tween()
	tween.tween_method(set_percent, 1.0, 0.0, 1)
	await tween.finished
	queue_free()
