extends Resource
class_name PlayerModifier

# --- STATS DASAR ---
@export var hp: float = 100.0
@export var dash_range: float = 600.0
@export var move_speed: float = 200.0
@export var base_damage: float = 20.0
@export var final_damage: float = 1.0 #Multiplicative

# --- STATS POSSESS & SKILL CURIAN ---
@export var borrowed_damage: float = 1.0 # (Grandma's Revenge)
@export var possess_damage: float = 1.0 # (Wolf's Grin)
@export var possesian_timing: float = 0 # (What Big Eyes...)
@export var borrowed_skill_duration: float = 12.0
@export var skill_echo_chance: float = 0.0 # (Arcane Echo)
@export var heal_on_miss: float = 0.0 # (House of Straw)
@export var shield_on_skill_use: float = 0.0 # (Astral Shield)

# --- STATS SUPER DASH (EXPLOSION) ---
@export var explosion_size: float = 1.0 #Multiplicative
@export var explosion_damage: float = 1.0
@export var super_dash_cost: int = 0 # (Big Bad Bargain)
@export var perfect_possess_super_charge_chance: float = 0.0 # (Lucky Foot)

# --- STATS DASH BIASA ---
@export var dash_duration: float = 0.1 # (Quick Getaway)
@export var refund_dash_chance: float = 0.0 #Multiplicative
@export var dash_cooldown_reduction: float = 0.1 #ultiplicative

# --- STATS SKILL CURIAN SPESIFIK ---
@export var homing_pierce: int = 0 # (Spectral Spike)
@export var homing_chain: int = 0 # (Chain Shot)
@export var slash_aoe: float = 1.0 # (Master's Cut)
@export var wolf_dash_explosion_damage: float = 0.0 # (Howling Gale)

# --- STATS SURVIVAL & UTILITAS ---
@export var healing_bonus: float = 10.0 
@export var healing_bonus_exit: float = 0.0
@export var healing_chance: float = 0.1 #Multiplacative
@export var slow_field: float = 0.0 # (McGregor's Garden)
@export var ressurection: int = 0 # (House of Brick)
@export var reroll_charges: int = 0
@export var frenzy_duration: float = 0.0 # (Hunter's Haste)


# Dictionary untuk menyimpan mode operasi ("add" or "multiply")
var op_modes := {}

func set_mode(stat_name: String, mode: String):
	# mode must be "add" or "multiply"
	if mode in ["add", "multiply"]:
		op_modes[stat_name] = mode
	else:
		push_warning("Invalid mode '%s' for stat '%s'" % [mode, stat_name])


# -----------------------------------------------------------------
func apply_modifier(other: PlayerModifier) -> PlayerModifier:
	# 1. Buat 'result' baru yang merupakan SALINAN dari 'self'
	var result := PlayerModifier.new()
	for key in get_property_list():
		var name = key.name
		# Lewati dictionary op_modes, kita hanya salin stat
		if name == "op_modes":
			continue
		
		# Salin nilai stat saat ini
		if typeof(result.get(name)) in [TYPE_FLOAT, TYPE_INT]:
			result.set(name, self.get(name))

	# 2. Terapkan 'other' (boon) ke 'result'
	# Kita HANYA loop 'op_modes' dari boon, 
	# karena itu adalah daftar stat yang ingin diubah
	for stat_name in other.op_modes:
		# Keamanan jika ada typo nama stat
		if (not stat_name in result):
			push_warning("Stat '%s' tidak ditemukan di PlayerModifier!" % stat_name)
			continue
			
		# Ambil nilai-nilainya
		var base_val = result.get(stat_name)    # (Stat 'result' saat ini)
		var other_val = other.get(stat_name)   # (Nilai dari boon)
		var mode = other.op_modes[stat_name] # ("add" atau "multiply")

		# Terapkan
		match mode:
			"add":
				result.set(stat_name, base_val + other_val)
			"multiply":
				result.set(stat_name, base_val * other_val)
	
	# 3. Kembalikan stat baru yang sudah dihitung
	return result
