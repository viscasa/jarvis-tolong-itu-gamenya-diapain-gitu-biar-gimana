extends BuffBase
class_name BuffWizard

func _init():
	buff_type = "Wizard"
	randomize() 

	var choice = randi_range(1, 5)
	match choice:
		1:
			_load_type_1()
		2:
			_load_type_2()
		3:
			_load_type_3()
		4:
			_load_type_4()
		5:
			_load_type_5()
	
	time_left = duration


func _load_type_1():
		modifier.borrowed_skill_duration = 0.4                   
		modifier.set_mode("borrowed_skill_duration", "add")

func _load_type_2():
	if modifier.refund_dash_chance==0.0:
		modifier.refund_dash_chance = 0.2       
		modifier.set_mode("refund_dash_chance", "add")
	else:
		modifier.refund_dash_chance = 1.2       
		modifier.set_mode("refund_dash_chance", "multiply")

func _load_type_3():
	if modifier.healing_bonus_exit==0.0:
		modifier.healing_bonus_exit = 10      
		modifier.set_mode("healing_bonus_exit", "add")
	else:
		modifier.healing_bonus_exit = 1.1       
		modifier.set_mode("healing_bonus_exit", "multiply")

func _load_type_4():
	modifier.explosion_size = 1.1        
	modifier.set_mode("explosion_size", "multiply")

func _load_type_5():
	modifier.possesian_timing = 0.2       
	modifier.set_mode("possesian_timing", "add")
