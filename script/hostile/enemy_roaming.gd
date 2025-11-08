extends CharacterBody2D

# --- Variabel ---
@export var speed: float = 10.0
@export var roam_radius: float = 100
@export var target_threshold: float = 10.0 # Seberapa dekat untuk dianggap "sampai"

# Titik pusat area roaming (akan diatur saat start)
var center_point: Vector2
# Titik tujuan saat ini
var current_target: Vector2


func _ready():
	# Atur titik pusat roaming ke posisi awal karakter
	center_point = global_position
	# Pilih target pertama untuk memulai
	_pick_new_target()


func _physics_process(delta):
	# 1. Periksa apakah kita sudah dekat dengan target
	if global_position.distance_to(current_target) < target_threshold:
		# Jika ya, pilih target baru
		_pick_new_target()

	# 2. Hitung arah ke target
	var direction = global_position.direction_to(current_target)

	# 3. Atur kecepatan ke arah target
	velocity = direction * speed

	# 4. Bergerak
	move_and_slide()


# Fungsi untuk memilih titik acak baru di dalam lingkaran
func _pick_new_target():
	# Dapatkan sudut acak (0 sampai 360 derajat)
	var random_angle = randf() * TAU # TAU = 2 * PI
	
	# Dapatkan jarak acak dari pusat (0 sampai roam_radius)
	# Kita gunakan sqrt(randf()) agar distribusinya merata di dalam lingkaran,
	# tapi untuk simpelnya, randf() * roam_radius juga oke.
	var random_distance = randf() * roam_radius
	
	# Hitung posisi offset dari pusat
	var offset = Vector2.from_angle(random_angle) * random_distance
	
	# Atur target baru
	current_target = center_point + offset
