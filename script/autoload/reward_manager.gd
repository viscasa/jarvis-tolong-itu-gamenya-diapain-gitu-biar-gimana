extends Node

var next_reward_id: String = "pig"

# FIX Bug 4: Tracking berdasarkan nama, bukan path
var collected_boon_names: Array[String] = []
var collected_boon_paths: Array[String] = [] # Keep for backward compatibility

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

# --- FUNGSI BARU ---
func register_boon_by_name(boon_name: String):
	if not boon_name in collected_boon_names:
		collected_boon_names.append(boon_name)
		print("✓ Registered boon: ", boon_name)

func unregister_boon_by_name(boon_name: String):
	var idx = collected_boon_names.find(boon_name)
	if idx != -1:
		collected_boon_names.remove_at(idx)
		print("✗ Unregistered boon: ", boon_name)

func is_boon_collected_by_name(boon_name: String) -> bool:
	return boon_name in collected_boon_names

func get_collected_boon_names() -> Array[String]:
	return collected_boon_names.duplicate()
# --- END FUNGSI BARU ---

func register_boon_as_collected(boon: BuffBase):
	# Update: Sekarang gunakan nama
	register_boon_by_name(boon.boon_name)
	
	# Keep path tracking for compatibility
	if not boon.resource_path.is_empty():
		if not boon.resource_path in collected_boon_paths:
			collected_boon_paths.append(boon.resource_path)

func is_boon_collected(boon_path: String) -> bool:
	return boon_path in collected_boon_paths

func reset_collected_boons():
	collected_boon_names.clear()
	collected_boon_paths.clear()
	print("Reset all collected boons")

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
				boon = BuffCinderella.new()
			chosen_effect_ids.append(boon.effect_id)
			cinderella_choices.append(boon)
			
		return cinderella_choices
		
	var giver_data = get_reward_data(boon_giver_id)

	if not giver_data or not giver_data.has("boon_folder_path"):
		return []

	var boon_folder_path = giver_data.boon_folder_path
	var available_boons: Array[BuffBase] = []

	var dir = DirAccess.open(boon_folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next().trim_suffix(".remap")
		
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path = boon_folder_path + file_name
				var boon_res = load(full_path)
				
				# FIX Bug 4: Cek berdasarkan nama, bukan path
				if boon_res and not is_boon_collected_by_name(boon_res.boon_name):
					available_boons.append(boon_res)
						
			file_name = dir.get_next().trim_suffix(".remap")

	available_boons.shuffle()
	
	return available_boons.slice(0, amount)
