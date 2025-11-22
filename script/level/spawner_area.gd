extends TileMapLayer
class_name TileMapEnemySpawner

# --- DEFINISI TIPE ENEMY ---
enum EnemyType {
	BROKEN_PUPPET = 0,
	WOLF = 1,
	SHOOTING_ENEMY = 2,
	DASH_SHOOTING_ENEMY = 3,
	RANDOM = -1
}

@export var enemies_to_spawn: Array[EnemyType] = []

@export var spawn_layer_id: int = 0

# Dictionary Path Resource (Sama seperti referensi Anda)
var enemy_paths = {
	EnemyType.BROKEN_PUPPET: "res://scene/hostile/broken_puppet.tscn",
	EnemyType.WOLF: "res://scene/hostile/wolf.tscn",
	EnemyType.SHOOTING_ENEMY: "res://scene/hostile/shooting_enemy.tscn",
	EnemyType.DASH_SHOOTING_ENEMY: "res://scene/hostile/dash_shooting_enemy.tscn"
}

# --- FUNGSI UTAMA ---
# Fungsi ini dipanggil oleh Room.gd nanti
func spawn_batch_enemies(target_container: Node2D) -> Array:
	var spawned_enemies_list: Array = []
	
	# 1. Ambil semua koordinat lantai yang valid
	var used_cells = get_used_cells_by_id(spawn_layer_id)
	
	if used_cells.is_empty():
		push_warning("TileMapSpawner: Tidak ada tile di layer " + str(spawn_layer_id))
		return []

	# 2. Acak urutan posisi lantai agar spawn menyebar random
	used_cells.shuffle()
	
	# Cek apakah lantai cukup untuk jumlah musuh
	if enemies_to_spawn.size() > used_cells.size():
		push_warning("TileMapSpawner: Jumlah musuh lebih banyak dari jumlah tile lantai!")
	
	# 3. Loop berdasarkan daftar enemy yang Anda set di Inspector
	var current_cell_index = 0
	
	for type_selection in enemies_to_spawn:
		# Pastikan kita tidak kehabisan lantai
		if current_cell_index >= used_cells.size():
			break
			
		var cell_coords = used_cells[current_cell_index]
		current_cell_index += 1
		
		# Tentukan tipe final (handle jika pilihannya RANDOM)
		var final_type = type_selection
		if final_type == EnemyType.RANDOM:
			# Pilih random dari 0 sampai 3
			final_type = randi_range(0, 3) as EnemyType
			
		# 4. Instantiate Musuh
		var enemy_instance = _create_enemy(final_type)
		if enemy_instance:
			target_container.add_child(enemy_instance, true) # Masukkan ke container (biasanya YSort/Node2D)
			
			# Set Posisi (Grid -> World Position) + Setengah ukuran tile agar di tengah
			enemy_instance.global_position = map_to_local(cell_coords)
			
			spawned_enemies_list.append(enemy_instance)
			
	return spawned_enemies_list

func _create_enemy(type: int) -> Node2D:
	if not enemy_paths.has(type):
		return null
		
	var path = enemy_paths[type]
	var scene = load(path)
	if scene:
		return scene.instantiate()
	return null
