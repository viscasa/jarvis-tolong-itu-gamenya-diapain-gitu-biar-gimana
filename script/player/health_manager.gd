extends Node2D
class_name HealthManager

signal health_changed(current_health, max_health)
signal no_health() 
signal resurrected # Sinyal baru untuk UI

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

func _ready():
	current_health = max_health

func heal(amount: float):
	# Ambil stat terbaru
	var stats = buff_manager.current_stats
	
	# Terapkan boon "Stolen Carrots"
	var final_heal = amount * stats.healing_bonus
	
	current_health += final_heal
	DamageNumber.display_number(final_heal, damage_number_origin, Color.GREEN, true)
	health_bar.value = current_health
	print("Player healed for ", final_heal)
# ------------------------------------
func take_damage(damage_amount: float, crit_multiplier: float = 1.0):
	# Jika damage_amount negatif, itu adalah HEAL
	if damage_amount < 0:
		heal(-damage_amount)
		return

	var final_damage = damage_amount*crit_multiplier - base_defense
	
	if final_damage < 1:
		final_damage = 1
	
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
