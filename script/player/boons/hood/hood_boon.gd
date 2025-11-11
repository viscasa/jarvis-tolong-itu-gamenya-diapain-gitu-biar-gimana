extends BuffBase
class_name BuffHood

enum BoonType { 
	GRANDMAS_REVENGE, 
	WOLFS_GRIN, 
	HUNTERS_HASTE, 
	WHAT_BIG_EYES, 
	PICNIC_BASKET 
}
@export var boon_type: BoonType = BoonType.GRANDMAS_REVENGE:
	set(value):
		boon_type = value
		_generate_boon() # Panggil ini saat 'boon_type' diubah di Inspector
# ---------------------------------------------------

func _init():
	buff_type = "Hood"
	# Panggil _generate_boon() saat pertama kali dibuat
	_generate_boon()

func _generate_boon():
	# Reset modifier & mode setiap kali di-generate
	modifier = PlayerModifier.new()
	modifier.op_modes = {}
	
	match boon_type:
		BoonType.GRANDMAS_REVENGE: _load_type_1()
		BoonType.WOLFS_GRIN: _load_type_2()
		BoonType.HUNTERS_HASTE: _load_type_3()
		BoonType.WHAT_BIG_EYES: _load_type_4()
		BoonType.PICNIC_BASKET: _load_type_5()
	
	time_left = duration

# Grandma's Revenge: +50% stolen skill damage
func _load_type_1():
	boon_name = "Grandma’s Revenge"
	boon_description = "Your stolen skills deal 50% more damage."
	modifier.borrowed_damage = 1.5
	modifier.set_mode("borrowed_damage", "multiply")

# Wolf’s Grin: +50% possess damage
func _load_type_2():
	boon_name = "Wolf’s Grin"
	boon_description = "Your Perfect Possess attacks deal 50% more damage."
	modifier.possess_damage = 1.5
	modifier.set_mode("possess_damage", "multiply")

# Hunter’s Haste: Frenzy
func _load_type_3():
	boon_name = "Hunter’s Haste"
	boon_description = "Killing 3 enemies within 5 seconds triggers FRENZY."
	modifier.frenzy_duration = 6
	modifier.set_mode("frenzy_duration", "add")

# What Big Eyes: Easier timing
func _load_type_4():
	boon_name = "What Big Eyes You Have"
	boon_description = "Your Perfect Possess timing window is 40% larger."
	modifier.possesian_timing = 0.052 # (+0.052s)
	modifier.set_mode("possesian_timing", "add")

# Picnic Basket Bomb
func _load_type_5():
	boon_name = "Picnic Basket Bomb"
	boon_description = "Your Super Dash has 25% larger area and deals 25% more damage."
	modifier.explosion_size = 1.25
	modifier.set_mode("explosion_size", "multiply")
	modifier.explosion_damage = 1.25
	modifier.set_mode("explosion_damage", "multiply")
