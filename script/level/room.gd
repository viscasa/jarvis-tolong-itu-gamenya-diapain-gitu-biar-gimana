extends Node2D
class_name Room


@export var reward_scene: PackedScene
@onready var wave_spawners: Node2D = $WaveSpawners
@onready var enemy_container: Node = $EnemyContainer
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition
@onready var reward_spawn_position: Marker2D = $RewardSpawnPosition
@onready var wave_spawner: Node2D = $WaveSpawners
@onready var door_container: Node2D = $DoorContainer
@export var boon_pickup: Area2D
var current_wave_index: int = 0
var enemies_remaining_in_wave: int = 0
var is_cleared: bool = false
var waves: Array[Node]

func _ready():
	waves = wave_spawners.get_children()
	_lock_all_doors()
	_start_wave(current_wave_index)
	var next_level = LevelManager.get_next_level()
	for door in door_container.get_children():
		door.next_scene_path = next_level
func _start_wave(index: int):
	AudioManager.change_bgm_to_combat()
	if index >= waves.size():
		_on_all_waves_cleared()
		return

	var wave_node = waves[index]

	var enemy_spawner = wave_node.get_children()

	enemies_remaining_in_wave = enemy_spawner.size()

	if enemies_remaining_in_wave == 0:
		_on_enemy_died() 
		return
	
	for spawner: EnemySpawner in enemy_spawner:
		var enemy = spawner.spawn_enemy()
		enemy_container.add_child(enemy, true)
		enemy.global_position = spawner.global_position
		enemy.stats.no_health.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_remaining_in_wave -= 1
	if enemies_remaining_in_wave <= 0:
		current_wave_index += 1
		call_deferred("_start_wave", current_wave_index)

func _on_all_waves_cleared():
	AudioManager.change_bgm_to_calm()
	is_cleared = true
	_spawn_reward()
	_unlock_all_doors()


func _spawn_reward():
	var reward_id_to_spawn = RewardManager.next_reward_id
	if reward_id_to_spawn == "":
		return

	if not boon_pickup:
		return
			
	
	boon_pickup.set_boon_giver_id(reward_id_to_spawn)
	
	RewardManager.next_reward_id = ""

func _lock_all_doors():
	for door in door_container.get_children():
		if door is Door:
			door.lock()

func _unlock_all_doors():
	var doors = door_container.get_children()
	if doors.is_empty():
		return
	
	var reward_choices = RewardManager.get_random_reward_choices(doors.size())
	
	for i in range(doors.size()):
		var door = doors[i]
		if door is Door:
			var reward_id = reward_choices[i]
			var reward_data = RewardManager.get_reward_data(reward_id)
			
			if reward_data:
				door.unlock(reward_id, load(reward_data.icon))
