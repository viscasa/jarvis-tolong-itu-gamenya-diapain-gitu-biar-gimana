extends BuffBase
class_name BuffWizard


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

# Master's Cut: Slash range increases
func _load_type_1():
	boon_name = "Master’s Cut"
	boon_description = "Your stolen skill 'Slash' has 100% larger range."
	modifier.slash_aoe = 2
	modifier.set_mode("slash_aoe", "multiply")

func _load_type_2(): #
	boon_name = "Ethereal Stride"
	boon_description = "Your stolen Wolf Dash now grants full invincibility for its entire duration."
	modifier.wolf_dash_invincible = 1 
	modifier.set_mode("wolf_dash_invincible", "add")

# Arcane Echo: Double-cast chance
func _load_type_3():
	boon_name = "Arcane Echo"
	boon_description = "Your stolen shooting skills have twice the bullets."
	modifier.bullet_multiplier = 2
	modifier.set_mode("bullet_multiplier", "multiply")

# Chain Shot: Homing bounces
func _load_type_4():
	boon_name = "Chain Shot"
	boon_description = "Your stolen skill 'Homming Bullets' now bounces to one nearby enemy."
	modifier.homing_chain = 1
	modifier.set_mode("homing_chain", "add")

# Astral Shield: Gain shield when casting
func _load_type_5():
	boon_name = "Astral Shield"
	boon_description = "Each time you use a stolen skill, gain a small shield for 5 seconds."
	modifier.shield_on_skill_use = 10.0 # (10 HP shield)
	modifier.set_mode("shield_on_skill_use", "add")
