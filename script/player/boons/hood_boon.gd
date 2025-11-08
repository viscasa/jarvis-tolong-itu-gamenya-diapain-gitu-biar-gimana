extends BuffBase
class_name BuffHood

func _init():
	buff_type = "Hood"
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
		modifier.base_damage = 4                   
		modifier.set_mode("base_damage", "add")

func _load_type_2():
		modifier.borrowed_damage = 8         
		modifier.set_mode("borrowed_damage", "add")

func _load_type_3():
	modifier.final_damage = 1.05       
	modifier.set_mode("final_damage", "multiply")

func _load_type_4():
	modifier.explosion_damage = 1.05        
	modifier.set_mode("explosion_damage", "multiply")

func _load_type_5():
	if modifier.frenzy_duration==0.0:
		modifier.frenzy_duration = 6       
		modifier.set_mode("frenzy_duration", "add")
	else:
		modifier.frenzy_duration = 2       
		modifier.set_mode("frenzy_duration", "add")

#TODO SPECIFIC ENEY TYPE
