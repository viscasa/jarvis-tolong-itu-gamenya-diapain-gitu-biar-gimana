extends Node2D
class_name Pin

# --- Skena Pin yang akan dilempar ---
@export var pin_scene: PackedScene

# --- Parameter Skill ---
@export var max_pins: int = 3
@export var pin_reload_time: float = 0.5 # Waktu untuk 1 pin
@export var max_distance: float = 100.0 # Jarak lempar maksimal
@export var pin_speed: float = 800.0 # Kecepatan pin terbang

# --- Referensi (akan di-set oleh SkillManager) ---
@export var player: Player
@export var dash_manager: DashManager
@export var super_dash: SuperDash

# --- State ---
var current_pins: int
var reload_timer: float = 0.0
var is_throwing: bool = false # Untuk cek is_casting_skill()

signal pin_count_changed(current_pins, max_pins)

func _ready() -> void:
	current_pins = max_pins
	# Beri tahu UI saat game dimulai
	emit_signal("pin_count_changed", current_pins, max_pins)

func _process(delta: float) -> void:
	if reload_timer > 0.0:
		reload_timer -= delta

# Fungsi publik untuk dicek oleh SkillManager
func is_active() -> bool:
	return is_throwing # Ini akan true/false sangat cepat

# Fungsi utama yang dipanggil SkillManager
func throw_pin() -> void:
	if reload_timer > 0.0:
		return
	
	# Cek 1: Punya pin?
	if current_pins <= 0:
		print("PIN: Habis!")
		return
		
	# Cek 2: Sedang melakukan skill lain? (Pastikan referensi sudah di-set)
	if not player or not dash_manager or not super_dash:
		push_error("Referensi Pin.gd belum di-set oleh SkillManager!")
		return
		
	if dash_manager.is_dashing or dash_manager.is_dash_moving or \
	   dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
	   super_dash.is_active():
		print("PIN: Tidak bisa, sedang sibuk!")
		return
		
	is_throwing = true
	
	# 1. Ambil posisi
	var player_pos = player.global_position
	var mouse_pos = player.get_global_mouse_position()
	
	# 2. Hitung arah dan jarak
	var direction = (mouse_pos - player_pos).normalized()
	# Jika arah 0 (mouse di player), lempar ke kanan saja
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
		
	var distance_to_mouse = player_pos.distance_to(mouse_pos)
	
	# 3. Terapkan batas jarak
	var target_distance = min(distance_to_mouse, max_distance)
	
	# 4. Habiskan pin & mulai reload
	current_pins -= 1
	emit_signal("pin_count_changed", current_pins, max_pins)
	print("PIN: Dilempar! Sisa: ", current_pins)
	if reload_timer <= 0.0 and current_pins < max_pins: # Mulai timer reload jika belum jalan
		reload_timer = pin_reload_time
		 
	# 5. Buat instance pin
	if not pin_scene:
		push_error("Pin.gd: pin_scene belum di-set di Inspector!")
		is_throwing = false
		return
		
	var pin_instance = pin_scene.instantiate()
	
	# 6. Tambahkan ke root tree (lebih aman untuk projectile)
	get_tree().root.add_child(pin_instance, true)
	
	# 7. Setup instance
	pin_instance.global_position = player_pos
	
	# Panggil fungsi 'launch' di skrip pin_instance
	if pin_instance.has_method("launch"):
		pin_instance.launch(direction, pin_speed, target_distance)
	else:
		push_error("Instance Pin (ThrownPin.tscn) tidak punya method 'launch(direction, speed, distance)'!")
		
	is_throwing = false # Selesai melempar (prosesnya instan)

func add_count() -> void:
	current_pins += 1
	print("PIN: ditambah!")
	emit_signal("pin_count_changed", current_pins, max_pins)
