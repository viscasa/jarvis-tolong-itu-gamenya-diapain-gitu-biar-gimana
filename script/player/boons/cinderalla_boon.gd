extends BuffBase
class_name BuffCinderella

var effect_id: int = 0


func _init():
	buff_type = "Cinderella"
	permanent = false # All Cinderella boons are instant effects
	randomize()
	
	effect_id = randi_range(1, 5) # We have 5 boons
	
	match effect_id:
		1: # Midnight Bargain
			boon_name = "Midnight Bargain"
			boon_description = "Remove 1 random boon and gain 2 new random boons."
		2: # Glass Slipper
			boon_name = "Glass Slipper"
			boon_description = "Remove 1 random boon and gain 1 boon from a chosen Giver."
		3: # Fairy Godmother’s Wish
			boon_name = "Fairy Godmother’s Wish"
			boon_description = "Reroll all of your current boons."
		4: # Rags to Riches
			boon_name = "Rags to Riches"
			boon_description = "Remove all current boons and gain +2 Max HP for each boon removed."
		5: # Royal Ball
			boon_name = "Royal Ball"
			boon_description = "Instantly gain 3 random new boons."
	
	duration = 0.1 # Instant effect, processed and removed immediately
	time_left = duration
