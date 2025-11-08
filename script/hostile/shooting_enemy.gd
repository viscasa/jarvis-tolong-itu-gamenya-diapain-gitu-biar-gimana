# ShootingEnemy.gd
# Musuh ini akan menjaga jarak (kiting).
# Saat menembak, dia akan diam sebentar (reload), lalu
# mondar-mandir (wander) selama sisa cooldown.
extends EnemyBase

@export var projectile_scene: PackedScene

# --- Pengaturan Kiting & Reposisi ---
@export var reposition_distance: float = 80.0 # Jarak "terlalu dekat" (akan mundur)
@export var reload_time: float = 0.5 # Waktu "diam" setelah nembak
@export var wander_range: float = 60.0 # Jarak mondar-mandir
@export var wander_speed_mult: float = 0.6 # Kecepatan mondar-mandir

# --- State Internal ---
enum AttackSubState { RELOADING, WANDERING }
var _attack_sub_state: AttackSubState = AttackSubState.RELOADING
var _attack_state_timer: float = 0.0
var _wander_target_pos: Vector2 = Vector2.ZERO


# -----------------
# LOGIKA STATE CHASE (Kiting / Jaga Jarak)
# -----------------
# Tujuan: Berhenti di "sweet spot" (antara reposition_distance & attack_range)
# Saat berhenti, EnemyBase akan memicu _perform_attack.
func _state_chase(delta):
	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
		return
		
	var distance_to_player = global_position.distance_to(player_target.global_position)
	var target_velocity: Vector2 = Vector2.ZERO

	# 1. ZONA "TERLALU JAUH" (Jarak > attack_range)
	if distance_to_player > attack_range:
		if nav_agent.is_navigation_finished():
			target_velocity = Vector2.ZERO
		else:
			var next_position = nav_agent.get_next_path_position()
			var direction = (next_position - global_position).normalized()
			target_velocity = direction * move_speed
			
	# 2. ZONA "TERLALU DEKAT" (Jarak <= reposition_distance)
	elif distance_to_player <= reposition_distance:
		var direction_to_player = (player_target.global_position - global_position).normalized()
		target_velocity = -direction_to_player * move_speed # Mundur

	# 3. ZONA "PAS / SWEET SPOT"
	else:
		target_velocity = Vector2.ZERO # Berhenti

	velocity = velocity.lerp(target_velocity, 8.0 * delta) 
	
	if velocity.x != 0:
		animated_sprite.flip_h = (velocity.x < 0)


# -----------------
# LOGIKA SERANGAN
# -----------------

# Dipanggil SATU KALI oleh EnemyBase saat serangan dimulai
func _perform_attack():
	# 1. Tembak
	#animated_sprite.play("attack")
	if not is_instance_valid(player_target): return
	var dir_to_player = global_position.direction_to(player_target.global_position)
	
	if dir_to_player.x != 0:
		animated_sprite.flip_h = (dir_to_player.x < 0)
	
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		get_parent().add_child(proj)
		proj.global_position = global_position
		proj.direction = dir_to_player
		proj.damage = stats.get_final_damage()
	else:
		print("ERROR: Projectile Scene belum di-set di " + name)
	
	# 2. Mulai fase "Reload" (diam)
	_attack_sub_state = AttackSubState.RELOADING
	_attack_state_timer = reload_time


# Dipanggil SETIAP FRAME oleh EnemyBase selama attack_cooldown
func _state_attack(delta):
	match _attack_sub_state:
		
		# Fase 1: Diam (Reload)
		AttackSubState.RELOADING:
			velocity = velocity.lerp(Vector2.ZERO, 15.0 * delta) # Berhenti
			_attack_state_timer -= delta
			
			if _attack_state_timer <= 0:
				# Reload selesai, mulai mondar-mandir
				_attack_sub_state = AttackSubState.WANDERING
				_pick_new_wander_target()

		# Fase 2: Mondar-mandir (Wander)
		AttackSubState.WANDERING:
			#animated_sprite.play("walk")
			var direction = global_position.direction_to(_wander_target_pos)
			var target_velocity = direction * move_speed * wander_speed_mult
			velocity = velocity.lerp(target_velocity, 5.0 * delta)
			
			# Jika sudah dekat, cari target baru
			if global_position.distance_to(_wander_target_pos) < 10:
				_pick_new_wander_target()

# Helper untuk mondar-mandir
func _pick_new_wander_target():
	var rand_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_wander_target_pos = global_position + rand_dir * wander_range


# Dipanggil oleh EnemyBase saat cooldown selesai
func _on_attack_timer_timeout():
	super._on_attack_timer_timeout() # Ini akan set state ke CHASE
	
	# Reset sub-state untuk serangan berikutnya
	_attack_sub_state = AttackSubState.RELOADING
