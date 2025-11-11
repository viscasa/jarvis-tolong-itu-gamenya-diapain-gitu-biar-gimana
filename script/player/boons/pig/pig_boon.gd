extends BuffBase
class_name BuffPig


enum BoonType { 
	HOUSE_OF_BRICK,
	PIGS_FEAST,
	HOUSE_OF_STICKS,
	HOUSE_OF_STRAW,
	BIG_BAD_BARGAIN
}
@export var boon_type: BoonType = BoonType.HOUSE_OF_BRICK:
	set(value):
		boon_type = value
		_generate_boon() # Panggil ini saat 'boon_type' diubah di Inspector
# ---------------------------------------------------

func _init():
	buff_type = "Pig"
	# Panggil _generate_boon() saat pertama kali dibuat
	_generate_boon()

func _generate_boon():
	# Reset modifier & mode setiap kali di-generate
	modifier = PlayerModifier.new()
	modifier.op_modes = {}
	
	match boon_type:
		BoonType.HOUSE_OF_BRICK: _load_type_1()
		BoonType.PIGS_FEAST: _load_type_2()
		BoonType.HOUSE_OF_STICKS: _load_type_3()
		BoonType.HOUSE_OF_STRAW: _load_type_4()
		BoonType.BIG_BAD_BARGAIN: _load_type_5()
	
	time_left = duration

# House of Brick: Resurrection
func _load_type_1():
	boon_name = "House of Brick"
	boon_description = "Gain one Resurrection. Revive with 50% HP."
	modifier.ressurection = 1
	modifier.set_mode("ressurection", "add")

# Pig's Feast: Heal to full
func _load_type_2():
	boon_name = "Pig’s Feast"
	boon_description = "Fully restore your HP."
	# Instant effect. Marked with a special code
	modifier.ressurection = 9999 # (Code for 'Pig’s Feast')
	permanent = false
	duration = 0.1

# House of Sticks: HP reduced, damage increased
func _load_type_3():
	boon_name = "House of Sticks"
	boon_description = "Max HP -20%, but all your skills deal +30% damage."
	modifier.hp = 0.8
	modifier.set_mode("hp", "multiply")
	modifier.borrowed_damage = 1.3
	modifier.possess_damage = 1.3
	modifier.explosion_damage = 1.3
	modifier.set_mode("possess_damage", "multiply")
	modifier.set_mode("borrowed_damage", "multiply")
	modifier.set_mode("explosion_damage", "multiply")

# House of Straw: Possess weaker, heal on miss
func _load_type_4():
	boon_name = "House of Straw"
	boon_description = "All skills deals -30% damage, but missing still heals you slightly."
	modifier.borrowed_damage = 0.7
	modifier.possess_damage = 0.7
	modifier.explosion_damage = 0.7
	modifier.set_mode("possess_damage", "multiply")
	modifier.set_mode("borrowed_damage", "multiply")
	modifier.set_mode("explosion_damage", "multiply")
	modifier.heal_on_miss = 5.0 # (Heals 5 HP)
	modifier.set_mode("heal_on_miss", "add")

# Big Bad Bargain: Lower damage, cheaper Super Dash
func _load_type_5():
	boon_name = "Big Bad Bargain"
	boon_description = "Your stolen skills deal -50% damage, but Super Dash now costs only 2 'Perfect Possess'."
	modifier.borrowed_damage = 0.5
	modifier.set_mode("borrowed_damage", "multiply")
	modifier.super_dash_cost = -1 # (3 - 1 = 2)
	modifier.set_mode("super_dash_cost", "add")
