extends Node2D
class_name HealthManager

signal health_changed(current_health, max_health)
signal no_health() 
signal resurrected # Sinyal baru untuk UI
var current_shield: float = 0.0
var shield_timer: Timer
signal shield_changed(current_shield, max_shield)
signal player_was_hit(hit_direction: Vector2)
var max_shield_amount: float = 0.0
@onready var damage_overlay: CanvasLayer = $"../DamageOverlay"
@onready var shield_bar: ProgressBar = $"../HealthBar/ShieldBar"
@onready var sprite: AnimatedSprite2D = $"../Sprite"
@export var max_health: float = 100.0:

	set(value):
		var old_max = max_health
		max_health = value
		# Update HP saat Max HP berubah (Boon "Fluffy Tail")
		if current_health > 0:
			if max_health > old_max:
				current_health += (max_health - old_max)
			current_health = min(current_health, max_health)
		
		if health_bar:
			health_bar.max_value = max_health
			health_bar.value = current_health
		if shield_bar:
			shield_bar.max_value = max_health + 10
			shield_bar.value = current_health
		_update_ui()
@export var base_defense: float = 2.0
@export var health_bar : ProgressBar
@export var heal_amount : float = 10.0
@onready var damage_number_origin: Node2D = $"../DamageNumberOrigin"

# --- TAMBAHKAN REFERENSI BUFFMANAGER ---
@onready var buff_manager: PlayerBuffManager = $"../BuffManager"

var current_health: float:
	set(value):
		current_health = clamp(value, 0, max_health)
		health_changed.emit(current_health, max_health)
		
		# --- PERBAIKAN LOGIKA KEMATIAN ---
		if current_health <= 0:
			# Cek boon "House of Brick"
			if buff_manager.current_stats.ressurection > 0:
				_try_resurrect()
			else:
				no_health.emit() # Baru benar-benar mati
		# ---------------------------------
		_update_ui()
func _ready():
	current_health = max_health

func heal(amount: float):
	# Ambil stat terbaru
	var stats = buff_manager.current_stats
	shield_timer = Timer.new()
	shield_timer.one_shot = true
	shield_timer.timeout.connect(_on_shield_timer_timeout)
	add_child(shield_timer)
	# Terapkan boon "Stolen Carrots"
	var final_heal = amount * stats.healing_bonus
	
	current_health += final_heal
	DamageNumber.display_number(final_heal, damage_number_origin, Color.GREEN, true)
	health_bar.value = current_health
	print("Player healed for ", final_heal)
# ------------------------------------
func take_damage(damage_amount: float, crit_multiplier: float = 1.0, is_melee := false, dir := Vector2(1.0, 1.0)):
	var stats = buff_manager.current_stats
	if randf() < stats.evasion_chance:
		print("EVASION! Serangan dihindari.")
		DamageNumber.display_number("MISS", damage_number_origin, Color.WHITE)
		return # <-- Langsung keluar, tidak menerima damage
	if damage_amount < 0:
		heal(-damage_amount)
		return
	if is_melee:
		player_was_hit.emit(dir)
	if damage_overlay:
		damage_overlay.flash()
	var tween = get_tree().create_tween()
	tween.tween_method(set_shader_blink_intensity, 1.0, 0.0, 0.3)
	var final_damage = damage_amount*crit_multiplier - base_defense
	var shake_tween = get_tree().create_tween()
	var shake_amount = 8.0 # Jarak getaran (piksel)
	var shake_duration = 0.02 # Waktu per getaran
	var original_pos = sprite.position

	# Goyang ke kanan, kiri, kanan, lalu kembali ke tengah
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos, shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos, shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(-shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos + Vector2(shake_amount, 0), shake_duration)
	shake_tween.tween_property(sprite, "position", original_pos, shake_duration)
	if final_damage < 1:
		final_damage = 1
	if current_shield > 0:
		var damage_to_shield = min(current_shield, final_damage)
		current_shield -= damage_to_shield
		final_damage -= damage_to_shield
		emit_signal("shield_changed", current_shield, max_shield_amount)
		DamageNumber.display_number(damage_to_shield, damage_number_origin, Color.BLUE)
	if final_damage > 0:
		if crit_multiplier > 1.0:
			DamageNumber.display_number(final_damage, damage_number_origin, Color.RED)
		else :
			DamageNumber.display_number(final_damage, damage_number_origin, Color.RED)
		current_health -= final_damage
		health_bar.value = current_health

# --- TAMBAHKAN FUNGSI RESURRECT BARU ---
func _try_resurrect():
	var stats = buff_manager.current_stats
	
	print("HOUSE OF BRICK! Anda hidup kembali!")
	
	# Kurangi 1 charge resurrection
	stats.ressurection -= 1
	
	# Buat buff "palsu" untuk meng-override stat
	var res_buff = BuffBase.new()
	res_buff.modifier.ressurection = -1 # (Kita kurangi 1)
	res_buff.modifier.set_mode("ressurection", "add")
	buff_manager.add_buff(res_buff) # Ini akan memicu _calculate_all
	
	# Hidup kembali dengan 50% HP
	current_health = max_health * 0.5
	emit_signal("resurrected")
func add_shield(amount: float):
	current_shield = amount
	max_shield_amount = amount 
	print("SHIELD DITAMBAH: ", current_shield)
	emit_signal("shield_changed", current_shield, max_shield_amount) 
	
	shield_timer.wait_time = 5.0 
	shield_timer.start()
	_update_ui()
func _on_shield_timer_timeout():
	# Waktu habis, hapus semua shield
	print("Astral Shield habis.")
	current_shield = 0.0
	max_shield_amount = 0.0 # Reset juga max-nya
	# Sinyal perubahan shield untuk UI
	emit_signal("shield_changed", current_shield, max_shield_amount)
	_update_ui()

func _update_ui():
	if health_bar:
		health_bar.value = current_health
	if shield_bar:
		print(current_shield)
		shield_bar.value = current_health + current_shield
		print("shield bar value:")
		print(shield_bar.value)
		print(health_bar.value)
func set_shader_blink_intensity(new_value : float):
	sprite.material.set_shader_parameter("blink_intensity", new_value)
