extends Resource
class_name PlayerModifier

@export var hp: float = 100.0
@export var dash_range: float = 600.0
@export var move_speed: float = 200.0
@export var base_damage: float = 20.0
@export var borrowed_damage: float = 10.0
@export var final_damage: float = 1.0 #Multiplicative
@export var explosion_size: float = 1.0 #Multiplicative
@export var explosion_damage: float = 20.0
@export var dash_duration: float = 0.1
@export var healing_bonus: float = 10.0 
@export var healing_bonus_exit: float = 0.0
@export var healing_chance: float = 0.1 #Multiplacative
@export var slow_field: float = 0.0
@export var borrowed_skill_duration: float = 12.0
@export var refund_dash_chance: float = 0.0 #Multiplicative
@export var dash_cooldown_reduction: float = 0.1 #ultiplicative
@export var ressurection: int = 0 
@export var reroll_charges: int = 0
@export var possesian_timing: float = 4.0
@export var frenzy_duration: float = 0.0





var op_modes := {}

func set_mode(stat_name: String, mode: String):
	# mode must be "add" or "multiply"
	if mode in ["add", "multiply"]:
		op_modes[stat_name] = mode
	else:
		push_warning("Invalid mode '%s' for stat '%s'" % [mode, stat_name])

func apply_modifier(other: PlayerModifier) -> PlayerModifier:
	var result := PlayerModifier.new()
	
	for key in result.get_property_list():
		var name = key.name
		if not (name in other):
			continue
		
		if typeof(result.get(name)) in [TYPE_FLOAT, TYPE_INT]:
			var base_val = self.get(name)
			var other_val = other.get(name)
			var mode = other.op_modes.get(name, "add")  # default = add

			match mode:
				"add":
					result.set(name, base_val + other_val)
				"multiply":
					result.set(name, base_val * other_val)
	
	return result
