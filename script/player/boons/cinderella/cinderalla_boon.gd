extends BuffBase
class_name BuffCinderella

var effect_id: int = 0

func _init():
	buff_type = "Cinderella"
	permanent = false 
	randomize()
	
	effect_id = randi_range(1, 5) 
	
	match effect_id:
		1: # Midnight Bargain
			boon_name = "Midnight Bargain"
			boon_description = "Remove 1 random boon and gain 3 new random boons."
			icon_id = 1

		2: # Glass Slipper
			boon_name = "The Invisible Gown"
			boon_description = "Remove all your current boons. Gain +2% permanent Evasion for each boon removed(max 50% evasion)."
			icon_id = 2
			
		3: # Fairy Godmother’s Wish
			boon_name = "Fairy Godmother’s Wish"
			boon_description = "Reroll all of your current boons."
			icon_id = 3
			
		4: # Rags to Riches
			boon_name = "Rags to Riches"
			boon_description = "Remove all current boons and gain +30 Max HP for each boon removed."
			icon_id = 4
			
		5: # Royal Ball
			boon_name = "Royal Ball"
			boon_description = "Instantly gain 2 random new boons."
			icon_id = 5
	
	duration = 0.1 
	time_left = duration
