extends Area2D
class_name Projectile

@export var speed: float = 350.0

var damage: float = 0.0
var direction: Vector2 = Vector2.ZERO

@onready var notifier = $VisibleOnScreenNotifier2D

func _ready():
	area_entered.connect(_on_area_entered)
	notifier.screen_exited.connect(_on_screen_exited)
	
	# Atur rotasi sprite agar menghadap ke arah proyektil
	# (Vector2(1,0) adalah 0 derajat/radian)
	rotation = direction.angle()

func _physics_process(delta):
	# Gerakkan proyektil ke arah 'direction'
	global_position += direction * speed * delta

func _on_area_entered(area):
	# Fungsi ini dipanggil saat CollisionShape2D kita menyentuh area lain
	
	# 1. Cek apakah yang kita sentuh adalah Hurtbox
	if area is Hurtbox:
		
		# 2. Cek apakah Hurtbox itu milik Player (bukan musuh lain)
		# (Kita asumsikan Hurtbox Player punya parent dengan class_name Player)
		if area.get_parent() is Player:
			
			# 3. Ambil node Stats dari Player
			var stats_node = area.get_parent().get_node_or_null("Stats")
			
			if stats_node:
				# 4. Berikan damage
				stats_node.take_damage(damage)
			
			# 5. Hancurkan proyektil
			queue_free()

func _on_screen_exited():
	# Hancurkan proyektil jika sudah keluar layar
	queue_free()
