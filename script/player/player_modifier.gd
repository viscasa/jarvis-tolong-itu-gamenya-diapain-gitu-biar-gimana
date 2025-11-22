extends Resource
class_name PlayerModifier

# --- STATS DASAR ---
@export var hp: float = 100.0
@export var dash_range: float = 600.0
@export var move_speed: float = 200.0
@export var base_damage: float = 2000.0
@export var final_damage: float = 1.0

# --- STATS POSSESS & SKILL CURIAN ---
@export var borrowed_damage: float = 1.0 # (Grandma's Revenge)
@export var possess_damage: float = 1.0 # (Wolf's Grin)
@export var possesian_timing: float = 0 # (What Big Eyes...)
@export var borrowed_skill_duration: float = 12.0
@export var bullet_multiplier: int = 1 # (arcane echo)
@export var heal_on_miss: float = 0.0 # (House of Straw)
@export var shield_on_skill_use: float = 0.0 # (Astral Shield)

# --- STATS SUPER DASH (EXPLOSION) ---
@export var explosion_size: float = 1.0
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
@export var wolf_dash_invincible: int = 0 # (Boon "Ethereal Stride")

# --- STATS SURVIVAL & UTILITAS ---
@export var healing_bonus: float = 1.0 
@export var healing_bonus_exit: float = 0.0
@export var healing_chance: float = 0.1 #Multiplacative
@export var evasion_chance: float = 0.0 
@export var ressurection: int = 0 # (House of Brick)
@export var reroll_charges: int = 0
@export var frenzy_duration: float = 0.0 # (Hunter's Haste)


var op_modes := {}

func set_mode(stat_name: String, mode: String):
	# mode must be "add" or "multiply"
	if mode in ["add", "multiply"]:
		op_modes[stat_name] = mode
	else:
		push_warning("Invalid mode '%s' for stat '%s'" % [mode, stat_name])


func apply_modifier(other: PlayerModifier) -> PlayerModifier:
	var result := PlayerModifier.new()
	for key in get_property_list():
		var name = key.name
		if name == "op_modes":
			continue
		
		if typeof(result.get(name)) in [TYPE_FLOAT, TYPE_INT]:
			result.set(name, self.get(name))

	for stat_name in other.op_modes:
		if (not stat_name in result):
			push_warning("Stat '%s' tidak ditemukan di PlayerModifier!" % stat_name)
			continue
			
		var base_val = result.get(stat_name)   
		var other_val = other.get(stat_name)   
		var mode = other.op_modes[stat_name] 

		match mode:
			"add":
				result.set(stat_name, base_val + other_val)
			"multiply":
				result.set(stat_name, base_val * other_val)
	
	return result
