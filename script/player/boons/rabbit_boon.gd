extends BuffBase
class_name BuffRabbit

func _init():
	buff_type = "Rabbit"
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
		modifier.hp = 20                   
		modifier.set_mode("hp", "add")

func _load_type_2():
		modifier.dash_duration = 1.1         
		modifier.set_mode("dash_duration", "multiply")

func _load_type_3():
	modifier.healing_bonus = 5        
	modifier.set_mode("healing_bonus", "add")


func _load_type_4():
	modifier.healing_chance = 1.2        
	modifier.set_mode("healing_chance", "add")


func _load_type_5():
	if modifier.slow_field==0.0:
		modifier.slow_field = 100       
		modifier.set_mode("slow_field", "add")
	else:
		modifier.slow_field = 1.2       
		modifier.set_mode("slow_field", "multiply")

#TODO RUSTY NAIL POISON EFFECT
