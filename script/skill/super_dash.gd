extends Node2D
class_name SuperDash

# ... (sinyal-sinyal tidak berubah) ...
signal super_dash_started
signal super_dash_charge_ended
signal super_dash_movement_ended # Sinyal ini aktif saat AOE terjadi
signal rechare_counter_changed

@onready var attack_manager: AttackManager = $"../../AttackManager"

# ... (export var tidak berubah) ...
@export var charge_time := 0.15
@export var charge_speed := 250.0
@export var dash_speed := 1500.0
@export var max_dash_distance := 200.0
@export var stop_friction_factor := 0.1
@export var aoe_radius := 50.0
@export var aoe_damage := 50.0
@export var super_dash_max : int = 1
@export var super_dash_counter : int = 1
@export var super_dash_recharge_counter : int = 0
@export var super_dash_recharge_needed : int = 3

# --- REFERENSI ---
var player: Player
var dash_manager: DashManager

# --- STATE ---
var is_charging: bool = false
var is_dashing: bool = false

var charge_timer: float = 0.0
var dash_move_timer: float = 0.0

var dash_direction := Vector2.ZERO
var charge_direction := Vector2.ZERO

# --- Node Internal untuk AOE ---
var aoe_area: Area2D
var aoe_shape: CollisionShape2D

# --- TAMBAHKAN INI ---
# Array untuk melacak siapa saja yang sudah kena damage di dash ini
var damaged_bodies_this_dash: Array = []

func _ready() -> void:
	aoe_area = Area2D.new()
	aoe_shape = CollisionShape2D.new()
# ... (setup shape tidak berubah) ...
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
	
	# --- TAMBAHKAN INI ---
	# Hubungkan sinyal 'body_entered' ke fungsi baru
	aoe_area.body_entered.connect(_on_aoe_body_entered)
	
	attack_manager.critical_circle.connect(_add_counter)
	super_dash_started.connect(_add_super_dash)
	rechare_counter_changed.connect(_process_recharge_counter)

# ... (is_active() dan start_super_dash() tidak berubah) ...
func is_active() -> bool:
	return is_charging or is_dashing
func start_super_dash() -> void:
	if super_dash_counter >= super_dash_max :
		return

	# Cek apakah sedang super dash, dash biasa, atau exit dash
	if is_active() or dash_manager.is_dashing or dash_manager.is_dash_moving or dash_manager.is_exit_dashing or dash_manager.is_exit_moving:
		return

	is_charging = true
	charge_timer = charge_time
	
	# Arah didapat langsung dari mouse
	dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	charge_direction = -dash_direction

	emit_signal("super_dash_started")

## Dipanggil oleh Player._physics_process
# ... (process_super_dash() tidak berubah) ...
func process_super_dash(delta: float) -> void:
	if is_charging:
		charge_timer -= delta
		if charge_timer <= 0.0:
			_start_dash_movement()
	
	# Logika is_dashing sekarang berdasarkan timer
	elif is_dashing:
		dash_move_timer -= delta
		if dash_move_timer <= 0.0:
			_end_dash_movement()

func _start_dash_movement() -> void:
	is_charging = false
	is_dashing = true
	
	# ... (perhitungan dash_move_timer tidak berubah) ...
	if dash_speed <= 0.0:
		# Menghindari error pembagian dengan nol
		push_error("SuperDash dash_speed tidak boleh nol!")
		dash_move_timer = 0.0
	else:
		dash_move_timer = max_dash_distance / dash_speed
	
	# Hitung ulang arah (agar bisa re-aim selagi charge)
	dash_direction = (player.get_global_mouse_position() - player.global_position).normalized()
	
	# --- TAMBAHKAN INI ---
	# Bersihkan daftar musuh yang sudah kena & aktifkan AOE
	damaged_bodies_this_dash.clear()
	aoe_shape.disabled = false
	aoe_area.monitoring = true
	# --------------------
	
	emit_signal("super_dash_charge_ended")

func _end_dash_movement() -> void:
	is_dashing = false
	dash_move_timer = 0.0 # Reset timer
	
	# ... (logika force stop tidak berubah) ...
	if player:
		player.velocity *= stop_friction_factor
	
	# --- TAMBAHKAN INI ---
	# Matikan AOE setelah dash selesai
	aoe_shape.disabled = true
	aoe_area.monitoring = false
	# --------------------
	
	emit_signal("super_dash_movement_ended")
	
	# --- HAPUS INI ---
	# _do_aoe_damage() # Kita tidak lagi memanggil AOE di akhir
	# -----------------

# ... (get_charge_velocity() dan get_dash_velocity() tidak berubah) ...
func get_charge_velocity() -> Vector2:
	if not is_charging:
		return Vector2.ZERO
	
	# Gerak mundur dengan kecepatan konstan
	return charge_direction * charge_speed
func get_dash_velocity() -> Vector2:
	if not is_dashing:
		return Vector2.ZERO
		
	# Melesat lurus ke target
	return dash_direction * dash_speed

# --- HAPUS FUNGSI DI BAWAH INI ---
# func _do_aoe_damage() -> void:
	# ... (SELURUH FUNGSI INI DIGANTIKAN OLEH _on_aoe_body_entered) ...
# -----------------------------------

# --- TAMBAHKAN FUNGSI BARU INI ---
# Fungsi ini akan dipanggil oleh sinyal 'body_entered'
func _on_aoe_body_entered(body) -> void:
	# Pastikan damage hanya terjadi saat sedang dash
	if not is_dashing:
		return
	
	if body == player:
		return # Jangan lukai diri sendiri
		
	# Cek apakah body ini sudah pernah kena damage di dash yang sama
	if body in damaged_bodies_this_dash:
		return
	
	# Jika body punya method "take_damage", panggil
	damaged_bodies_this_dash.append(body)
	attack_manager.attack(body, false, aoe_damage)
# ---------------------------------

# ... (fungsi _reset dan _add tidak berubah) ...
func _reset_super_dash_counter() :
	super_dash_counter = 0

func _add_super_dash() :
	if (super_dash_counter+1>super_dash_max) :
		return
	super_dash_counter+=1

func _process_recharge_counter() -> void :
	if super_dash_recharge_counter >= super_dash_recharge_needed :
		super_dash_counter = 0
		super_dash_recharge_counter = 0

func _add_counter() :
	super_dash_recharge_counter += 1
	emit_signal("rechare_counter_changed")
