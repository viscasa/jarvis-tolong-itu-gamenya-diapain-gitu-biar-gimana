extends Node
class_name PlayerBuffManager

@export var base_stats: PlayerModifier = PlayerModifier.new() # Stat dasar player
var current_stats: PlayerModifier = PlayerModifier.new()
var list_of_buffs: Array[BuffBase] = []

signal buffs_updated(current_stats: PlayerModifier)

func _ready():
	# Inisialisasi stat awal (Anda bisa atur base_stats di Inspector)
	_calculate_all()

func add_buff(buff: BuffBase):
	# (Logika Cinderella Anda sudah bagus, kita tambahkan Pig's Feast)
	
	if buff.buff_type == "Cinderella":
		_handle_cinderella_effect(buff)
		
	elif buff.buff_type == "Pig" and buff.modifier.ressurection == 9999: # (Contoh ID untuk Pig's Feast)
		# Ini adalah Pig's Feast (Heal to Full)
		var player_stats = get_parent().get_node("Stats") # Asumsi Stats di Player
		player_stats.current_health = player_stats.max_health
		# Jangan tambahkan ke list, ini efek instan
	
	else:
		# Ini adalah boon stat normal
		list_of_buffs.append(buff)
		_calculate_all() # Hitung ulang stat

func remove_buff(buff_type: String):
	list_of_buffs = list_of_buffs.filter(func(b): return b.buff_type != buff_type)
	_calculate_all()

func remove_expired_buffs():
	var before := list_of_buffs.size()
	list_of_buffs = list_of_buffs.filter(func(b): return b.duration == 0 or b.time_left > 0)
	if before != list_of_buffs.size():
		_calculate_all()

# --- PERBAIKAN PENTING DI SINI ---
# Fungsi ini sekarang menggunakan 'apply_modifier' yang benar
func _calculate_all():
	# 1. Mulai dengan stat dasar murni
	var new_stats = base_stats 
	
	# 2. Tumpuk (apply) setiap buff satu per satu
	for buff in list_of_buffs:
		new_stats = new_stats.apply_modifier(buff.modifier)
		
	# 3. Simpan hasilnya
	current_stats = new_stats
	
	# 4. Beri tahu 'Player' (dan skrip lain) bahwa stat sudah berubah
	emit_signal("buffs_updated", current_stats)
# ---------------------------------

func _process(delta: float) -> void:
	# (Ini untuk boon non-permanen seperti 'Hunter's Haste')
	for buff in list_of_buffs:
		buff.update(delta)
	remove_expired_buffs()
	
# (Sisa fungsi Anda: _create_random_buff, _handle_cinderella_effect, dll.)
# ...
func _create_random_buff(exclude: Array[String] = []) -> BuffBase:
	var pool = [BuffRabbit, BuffHood, BuffWizard, BuffPig]
	pool = pool.filter(func(buff_class): return buff_class.new().buff_type not in exclude)
	if pool.is_empty():
		return BuffBase.new()
	var chosen_boon = pool[randi_range(0, pool.size() - 1)]
	return chosen_boon.new()

func _handle_cinderella_effect(buff: BuffCinderella):
	match buff.effect_id:
		1:
			_trade_and_gain_buffs(1, 2) # (Sesuai ide baru Anda)
		2:
			_gain_random_buffs(3) # (Sesuai ide baru Anda)
		3:
			_reroll_all_buffs()
		4:
			_trade_for_specific() # (Glass Slipper)
		5:
			_trade_all_for_hp() # (Rags to Riches)
	
	# Boon Cinderella adalah instan, langsung hapus
	# remove_buff(buff.buff_type) # (Hati-hati, ini akan menghapus SEMUA buff Cinderella)
	_calculate_all() # Hitung ulang setelah selesai

func _trade_and_gain_buffs(trade_count: int, gain_count: int):
	for i in range(trade_count):
		if list_of_buffs.size() > 0:
			var idx = randi_range(0, list_of_buffs.size() - 1)
			list_of_buffs.remove_at(idx)
	_gain_random_buffs(gain_count) # Panggil fungsi di bawah

func _gain_random_buffs(amount: int):
	for i in range(amount):
		list_of_buffs.append(_create_random_buff())
	# (Jangan panggil _calculate_all() di sini, panggil di 'add_buff' saja)

func _reroll_all_buffs():
	var new_buff_count = list_of_buffs.size()
	list_of_buffs.clear()
	for i in range(new_buff_count):
		list_of_buffs.append(_create_random_buff())

func _trade_for_specific():
	# (Logika untuk 'Glass Slipper')
	pass

func _trade_all_for_hp():
	# (Logika untuk 'Rags to Riches')
	pass
