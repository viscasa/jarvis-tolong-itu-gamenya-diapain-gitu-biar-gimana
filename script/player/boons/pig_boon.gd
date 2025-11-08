extends BuffBase
class_name BuffPig

func _init():
	buff_type = "Pig"
	randomize() 

	var choice = randi_range(1, 7)
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
		6:
			_load_type_4()
		7:
			_load_type_5()
	
	time_left = duration


func _load_type_1():
		modifier.ressurection = 1                   
		modifier.set_mode("ressurection", "add")

func _load_type_2():
	modifier.reroll_charges = 2  
	modifier.set_mode("reroll_charges", "add")

#TODO GET CURRENT PLAYER HP to get 70% surpluss
func _load_type_3():
	modifier.hp = 1.7        
	modifier.set_mode("hp", "multiply")

func _load_type_4():
	modifier.hp = -20        
	modifier.set_mode("hp", "add")

func _load_type_5():
	modifier.borrowed_skill_duration = -1        
	modifier.set_mode("borrowed_skill_duration", "add")

#TODO SUBTITUION OR ENEMYE SPECIFIC
func _load_type_6():
	pass
