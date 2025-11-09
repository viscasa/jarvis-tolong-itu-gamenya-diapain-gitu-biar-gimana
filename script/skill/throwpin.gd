extends CharacterBody2D
class_name ThrownPin

@onready var stats: Stats = $Stats
@onready var health_bar: ProgressBar = $HealthBar
@onready var attack_timer: Timer = $AttackTimer

var speed: float = 0.0
var direction: Vector2 = Vector2.ZERO
var distance_to_travel: float = 0.0
var damage: float = 10.0 # Atur damage di sini
var duration: float = 3

var distance_traveled: float = 0.0

# Fungsi ini dipanggil oleh Pin.gd
func launch(_direction: Vector2, _speed: float, _distance: float):
	direction = _direction
	speed = _speed
	distance_to_travel = _distance
	attack_timer.start(duration)

func _ready() -> void:
	health_bar.max_value = stats.max_health
	health_bar.value = stats.current_health
	stats.no_health.connect(_on_death)

func _physics_process(delta: float) -> void:
	if speed == 0.0: # Belum di-launch
		return
		
	# Hitung pergerakan
	var move_amount = speed * delta
	
	# Cek apakah akan melebihi jarak
	if distance_traveled + move_amount >= distance_to_travel:
		# Sampai di tujuan
		global_position += direction * (distance_to_travel - distance_traveled)
		_stop_and_delete() # Berhenti di titik maks
		return
		
	# Bergerak
	global_position += direction * move_amount
	distance_traveled += move_amount

func _stop_and_delete() -> void:
	speed = 0.0 # Hentikan pergerakan
	# Mungkin tambahkan efek ledakan/animasi di sini

func _on_death():
	print(name + " mati!")
	
	set_physics_process(false)
	#$CollisionShape2D.disabled = true
	#if $Hurtbox: 
		#$Hurtbox/CollisionShape2D.disabled = true
	#
	#await animated_sprite.animation_finished
	var player = get_tree().get_nodes_in_group("player")[0]
	player.morph(name)
	queue_free()

func _on_attack_timer_timeout() -> void:
	_on_death()

func _on_hurtbox_player_auto_exit() -> void:
	attack_timer.start(duration)
	
func _on_hurtbox_player_possessed() -> void:
	attack_timer.stop()
