extends BuffBase
class_name BuffRabbit

enum BoonType { 
	FLUFFY_TAIL, 
	STOLEN_CARROTS, 
	QUICK_GETAWAY, 
	LUCKY_FOOT, 
	SOFT_FUR,
}
@export var boon_type: BoonType = BoonType.FLUFFY_TAIL:
	set(value):
		boon_type = value
		_generate_boon() 
func _init():
	buff_type = "Rabbit"
	_generate_boon()

func _generate_boon():
	modifier = PlayerModifier.new()
	modifier.op_modes = {}
	
	match boon_type:
		BoonType.FLUFFY_TAIL: _load_type_1()
		BoonType.STOLEN_CARROTS: _load_type_2()
		BoonType.QUICK_GETAWAY: _load_type_3()
		BoonType.LUCKY_FOOT: _load_type_4()
		BoonType.SOFT_FUR: _load_type_5()
	
	time_left = duration
# Fluffy Tail: + Max HP
func _load_type_1():
	icon_id = 11
	boon_name = "Fluffy Tail"
	boon_description = "Permanently increases your Max HP by 40."
	modifier.hp = 40.0
	modifier.set_mode("hp", "add")
	boon_icon = load("res://icon.svg")


# Stolen Carrots: + Healing
func _load_type_2():
	icon_id = 12
	boon_name = "Stolen Carrots"
	boon_description = "All healing you receive is 30% more effective."
	modifier.healing_bonus = 1.3
	modifier.set_mode("healing_bonus", "multiply")
	boon_icon = load("res://icon.svg")
	

# Quick Getaway: Longer dash
func _load_type_3():
	icon_id = 13
	boon_name = "Quick Getaway"
	boon_description = "Your standard dash distance is increased by 50%."
	modifier.dash_range = 1.5   # 50% lebih jauh
	modifier.set_mode("dash_range", "multiply")
	boon_icon = load("res://icon.svg")
	

# Lucky Foot: 20% chance instant Super Dash
func _load_type_4():
	icon_id = 14
	boon_name = "Lucky Foot"
	boon_description = "Each Perfect Possess has a 15% chance to instantly recharge Super Dash."
	modifier.perfect_possess_super_charge_chance = 0.15
	modifier.set_mode("perfect_possess_super_charge_chance", "add")
	boon_icon = load("res://icon.svg")
	

func _load_type_5():
	icon_id = 15
	boon_name = "Soft Fur" 
	boon_description = "Grants a 15% chance to evade all incoming damage (max 50% evasion)."
	modifier.evasion_chance = 0.15
	modifier.set_mode("evasion_chance", "add") 
	boon_icon = load("res://icon.svg")
