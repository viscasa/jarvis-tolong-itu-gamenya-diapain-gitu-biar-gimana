extends Node2D
class_name Room


@export var reward_scene: PackedScene
@export var boon_pickup: BoonPickup
@export_enum("move_northeast", "move_northwest", "move_southwest", "move_southeast") var player_start_animation:String = ""
@onready var wave_spawners: Node2D = $WaveSpawners
@onready var enemy_container: Node = $EnemyContainer
@onready var player_spawn_position: Marker2D = $PlayerSpawnPosition
@onready var reward_spawn_position: Marker2D = $RewardSpawnPosition
@onready var wave_spawner: Node2D = $WaveSpawners
@onready var door_container: Node2D = $DoorContainer
@onready var move_player: AnimationPlayer = $MovePlayer
var current_wave_index: int = 0
var enemies_remaining_in_wave: int = 0
var is_cleared: bool = false
@export var is_first_level : bool = false
@export var is_tutorial : bool = false
var is_reward_spawned : bool = false
var is_reward_picked : bool = false
var waves: Array[Node]

func _ready():
	var next_level = LevelManager.get_next_level()
	for door in door_container.get_children():
		door.next_scene_path = next_level
	if player_start_animation :
		move_player.play(player_start_animation)
		await move_player.animation_finished
	if boon_pickup and is_first_level :
		_spawn_reward()
		boon_pickup.boon_picked.connect(_start_wave.bind(current_wave_index))
	if boon_pickup and !is_first_level:
		boon_pickup.boon_picked.connect(_unlock_all_doors)
		_lock_all_doors()
		_start_wave(current_wave_index)
	if is_tutorial :
		_unlock_all_doors()

#func _start_wave(index: int):
	#AudioManager.change_bgm_to_combat()
	#if index >= waves.size():
		#_on_all_waves_cleared()
		#return
#
	#var wave_node = waves[index]
#
	#var enemy_spawner = wave_node.get_children()
#
	#enemies_remaining_in_wave = enemy_spawner.size()
#
	#if enemies_remaining_in_wave == 0:
		#_on_enemy_died() 
		#return
	#
	#for spawner: EnemySpawner in enemy_spawner:
		#var enemy = spawner.spawn_enemy()
		#enemy_container.add_child(enemy, true)
		#enemy.global_position = spawner.global_position
		#enemy.stats.no_health.connect(_on_enemy_died)

func _start_wave(index: int):
	AudioManager.change_bgm_to_combat()
	
	# 1. Ambil daftar Wave (Wave1, Wave2, dst) dari anak-anak WaveSpawners
	var waves_list = wave_spawners.get_children()
	
	if index >= waves_list.size():
		_on_all_waves_cleared()
		return

	# 2. Ambil Node Wave saat ini (Misal: Node "Wave1" atau "Wave2")
	var current_wave_node = waves_list[index]
	
	# 3. Ambil semua Spawner yang ada DI DALAM Wave tersebut
	# (Bisa 1 TileMapLayer, bisa 2, dst)
	var spawners_in_this_wave = current_wave_node.get_children()
	
	var all_spawned_enemies_in_wave = []
	
	# 4. Loop setiap spawner dan jalankan spawn_batch_enemies
	for spawner in spawners_in_this_wave:
		# Pastikan child tersebut memang script spawner kita
		if spawner is TileMapEnemySpawner:
			var enemies = spawner.spawn_batch_enemies(enemy_container)
			all_spawned_enemies_in_wave.append_array(enemies)
		else:
			push_warning("Room: Ada node di dalam Wave yang bukan TileMapEnemySpawner: " + spawner.name)

	# 5. Hitung total musuh dari semua spawner di wave ini
	enemies_remaining_in_wave = all_spawned_enemies_in_wave.size()

	if enemies_remaining_in_wave == 0:
		# Jika wave kosong (lupa isi musuh?), langsung lanjut/selesai
		_on_enemy_died() 
		return
	
	# 6. Koneksikan signal kematian
	for enemy in all_spawned_enemies_in_wave:
		if enemy.has_node("Stats"): 
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
	if is_first_level :
		_unlock_all_doors()

func _spawn_reward():
	if is_reward_spawned :
		return
	var reward_id_to_spawn = RewardManager.next_reward_id
	if reward_id_to_spawn == "":
		return

	if not boon_pickup:
		return
			
	
	boon_pickup.set_boon_giver_id(reward_id_to_spawn)
	is_reward_spawned = true
	
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
