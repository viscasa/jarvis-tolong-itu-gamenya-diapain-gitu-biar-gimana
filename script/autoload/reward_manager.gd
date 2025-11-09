extends Node

var next_reward_id: String = ""

var reward_database: Dictionary = {
	"cinderella": {
		#TODO: buat scene masing masing boon
		#"scene": preload("res://Rewards/BoonCinderella.tscn"),
		"icon": "res://assets/temp/0f93f5d0b8f66f7070cb88e3c2922be7.jpg"
	},
	"red_riding_hood": {
		"icon": "res://assets/temp/download.png"
		#"scene": 
	},
	#TODO semua boon
}

func get_random_reward_choices(amount: int):
	var all_rewards = reward_database.keys()
	all_rewards.shuffle() 
	return all_rewards.slice(0, amount) 

func get_reward_data(id: String):
	if reward_database.has(id):
		return reward_database[id]
	return null 
