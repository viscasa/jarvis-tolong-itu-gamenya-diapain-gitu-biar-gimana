extends BuffBase
class_name BuffCinderella

var effect_id: int = 0

func _init():
	buff_type = "Cinderella"
	randomize()
	effect_id = randi_range(1, 3) # only 3 main effects
	if effect_id == 2:
		duration = 4.0
		permanent = false
	else:
		duration = 1.0
		permanent = false
	time_left = duration
