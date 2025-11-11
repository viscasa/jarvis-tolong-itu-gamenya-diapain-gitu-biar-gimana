extends BuffBase
class_name BuffRabbit

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
# Fluffy Tail: + Max HP
func _load_type_1():
	boon_name = "Fluffy Tail"
	boon_description = "Permanently increases your Max HP by 40."
	modifier.hp = 40.0
	modifier.set_mode("hp", "add")

# Stolen Carrots: + Healing
func _load_type_2():
	boon_name = "Stolen Carrots"
	boon_description = "All healing you receive is 30% more effective."
	modifier.healing_bonus = 1.3
	modifier.set_mode("healing_bonus", "multiply")

# Quick Getaway: Longer dash
func _load_type_3():
	boon_name = "Quick Getaway"
	boon_description = "Your standard dash distance is increased by 80%."
	modifier.dash_duration = 1.8
	modifier.set_mode("dash_duration", "multiply")

# Lucky Foot: 20% chance instant Super Dash
func _load_type_4():
	boon_name = "Lucky Foot"
	boon_description = "Each Perfect Possess has a 15% chance to instantly recharge Super Dash."
	modifier.perfect_possess_super_charge_chance = 0.15
	modifier.set_mode("perfect_possess_super_charge_chance", "add")

func _load_type_5():
	boon_name = "Soft Fur" 
	boon_description = "Grants a 20% chance to evade all incoming damage."
	modifier.evasion_chance = 0.2
	modifier.set_mode("evasion_chance", "add") 
