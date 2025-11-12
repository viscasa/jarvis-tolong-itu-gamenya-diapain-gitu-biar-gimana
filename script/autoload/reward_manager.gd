extends Node

var next_reward_id: String = "pig"
signal got_buff
var showing_reward_screen := false
var reward_database: Dictionary = {
	"cinderella": {
		"icon": "res://assets/temp/0f93f5d0b8f66f7070cb88e3c2922be7.jpg",
		"boon_folder_path": "res://script/player/boons/cinderella/",
		"name": "Conspicuous Cinderella"
	},
	"red_riding_hood": {
		"icon": "res://assets/temp/download.png",
		"boon_folder_path": "res://script/player/boons/hood/",
		"name": "Vengeful Red Riding Hood"
	},
	#TODO icon beneran
	"rabbit": { 
		"icon": "res://icon.svg",
		"boon_folder_path": "res://script/player/boons/rabbit/",
		"name": "Mischievous Peter Rabbit"
	},
	"wizard": {
		"icon": "res://icon.svg",
		"boon_folder_path": "res://script/player/boons/wizard/",
		"name": "Wise Wizard of the West"
	},
	"pig": {
		"icon": "res://icon.svg",
		"boon_folder_path": "res://script/player/boons/pig/",
		"name": "Bountiful Piggies"
	}
}

var collected_boon_paths: Array[String] = []

func register_boon_as_collected(boon: BuffBase):
	if boon.resource_path and not boon.resource_path in collected_boon_paths:
		collected_boon_paths.append(boon.resource_path)
		print("Boon dikoleksi: ", boon.resource_path)

func reset_collected_boons():
	collected_boon_paths.clear()

func get_random_reward_choices(amount: int):
	var all_rewards = reward_database.keys()
	all_rewards.shuffle() 
	return all_rewards.slice(0, amount) 

func get_reward_data(id: String):
	if reward_database.has(id):
		return reward_database[id]
	return null

func get_boon_choices(boon_giver_id: String, amount: int) -> Array[BuffBase]:
	if boon_giver_id == "cinderella":
		var cinderella_choices: Array[BuffBase] = []
		var chosen_effect_ids: Array[int] = [] 
		
		for i in range(amount):
			var boon = BuffCinderella.new()
			
			while boon.effect_id in chosen_effect_ids:
				print("Cinderella duplicate found (ID: %s). Re-rolling..." % boon.effect_id)
				boon = BuffCinderella.new()
			chosen_effect_ids.append(boon.effect_id)
			cinderella_choices.append(boon)
			
		return cinderella_choices
	var giver_data = get_reward_data(boon_giver_id)

	if not giver_data or not giver_data.has("boon_folder_path"):
		print("ERROR: Boon Giver ID tidak valid: ", boon_giver_id)
		return []

	var boon_folder_path = giver_data.boon_folder_path
	var available_boons: Array[BuffBase] = []

	var dir = DirAccess.open(boon_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path = boon_folder_path + file_name
				
				if not full_path in collected_boon_paths:
					var boon_res = load(full_path)
					if boon_res:
						available_boons.append(boon_res)
						
			file_name = dir.get_next()
	else:
		print("ERROR: Tidak bisa membuka folder boon: ", boon_folder_path)

	available_boons.shuffle()
	
	return available_boons.slice(0, amount)
