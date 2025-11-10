extends Node2D
class_name Room


@export var player_scene: PackedScene
@export var reward_scene: PackedScene
@onready var wave_spawners: Node2D = $WaveSpawners
@onready var enemy_container: Node = $EnemyContainer
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition
@onready var reward_spawn_position: Marker2D = $RewardSpawnPosition
@onready var wave_spawner: Node2D = $WaveSpawners
@onready var door_container: Node2D = $DoorContainer

var current_wave_index: int = 0
var enemies_remaining_in_wave: int = 0
var is_cleared: bool = false
var waves: Array[Node]



func _ready():
	waves = wave_spawners.get_children()
	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = player_spawn_position.global_position
	_lock_all_doors()
	_start_wave(current_wave_index)


func _start_wave(index: int):
	print("wave " + str(index))
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
		enemy_container.add_child(enemy)
		enemy.global_position = spawner.global_position
		enemy.stats.no_health.connect(_on_enemy_died)

func _on_enemy_died():
	enemies_remaining_in_wave -= 1
	if enemies_remaining_in_wave <= 0:
		current_wave_index += 1
		call_deferred("_start_wave", current_wave_index)

func _on_all_waves_cleared():
	print("room cleared")
	is_cleared = true
	_spawn_reward()
	_unlock_all_doors()


func _spawn_reward():
	if not reward_scene:
		return

	var reward = reward_scene.instantiate()
	add_child(reward)
	reward.global_position = reward_spawn_position.global_position

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
