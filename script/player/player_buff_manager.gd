extends Node
class_name PlayerBuffManager

@export var base_stats: PlayerModifier = PlayerModifier.new() # Stat dasar player
var current_stats: PlayerModifier = PlayerModifier.new()
var list_of_buffs: Array[BuffBase] = []
var frenzy_kill_count: int = 0
var frenzy_timer: Timer
signal buffs_updated(current_stats: PlayerModifier)

func _ready():
	_calculate_all()
	frenzy_timer = Timer.new()
	frenzy_timer.wait_time = 5.0 
	frenzy_timer.one_shot = true
	frenzy_timer.timeout.connect(_on_frenzy_timer_timeout)
	add_child(frenzy_timer)

func add_buff(buff: BuffBase):
	# (Logika Cinderella Anda sudah bagus, kita tambahkan Pig's Feast)
	
	if buff.buff_type == "Cinderella":
		_handle_cinderella_effect(buff)
		
	elif buff.buff_type == "Pig" and buff.modifier.ressurection == 9999: # (Contoh ID untuk Pig's Feast)
		# Ini adalah Pig's Feast (Heal to Full)
		var player_stats = get_parent().get_node("HealthManager") # Asumsi Stats di Player
		player_stats.current_health = player_stats.max_health
		# Jangan tambahkan ke list, ini efek instan
	
	else:
		# Ini adalah boon stat normal
		list_of_buffs.append(buff)
		RewardManager.register_boon_as_collected(buff)
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
	var new_stats = base_stats 
	
	for buff in list_of_buffs:
		new_stats = new_stats.apply_modifier(buff.modifier)
		
	current_stats = new_stats
	
	emit_signal("buffs_updated", current_stats)
# ---------------------------------

func _process(delta: float) -> void:
	var needs_recalc = false
	for buff in list_of_buffs:
		if not buff.permanent:
			buff.update(delta)
			if buff.time_left == 0:
				needs_recalc = true # Tandai untuk dihapus
	
	if needs_recalc:
		remove_expired_buffs()
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
			_trade_for_specific() # (Glass Slipper)
		3:
			_reroll_all_buffs()
		4:
			_trade_all_for_hp() # (Rags to Riches)
		5:
			_gain_random_buffs(3) # (Sesuai ide baru Anda)
	
	# Boon Cinderella adalah instan, langsung hapus
	# remove_buff(buff.buff_type) # (Hati-hati, ini akan menghapus SEMUA buff Cinderella)
	_calculate_all() 

func _trade_and_gain_buffs(trade_count: int, gain_count: int):
	print("--- CINDERELLA: Midnight Bargain! ---")
	print("Menukar %s boon acak..." % trade_count)
	for i in range(trade_count):
		if list_of_buffs.size() > 0:
			var idx = randi_range(0, list_of_buffs.size() - 1)
			var removed_boon = list_of_buffs.pop_at(idx)
			print("  Boon dihapus: ", removed_boon.boon_name)
			
	_gain_random_buffs(gain_count) # Panggil fungsi di bawah

func _gain_random_buffs(amount: int):
	print("Mendapat %s boon baru!" % amount)
	var pool = _get_full_boon_pool(["Cinderella"])
	var new_boons = _get_random_buffs_from_pool(amount, pool)
	
	if new_boons.is_empty():
		print("... Tidak ada boon baru yang tersedia!")
		return
	for new_boon in new_boons:
		list_of_buffs.append(new_boon)
		RewardManager.register_boon_as_collected(new_boon)
		print("  Boon didapat: ", new_boon.boon_name)

func _reroll_all_buffs():
	print("--- CINDERELLA: Fairy Godmother’s Wish! ---")
	var new_buff_count = list_of_buffs.size()
	print("Menghapus %s boon dan menggantinya..." % new_buff_count)
	list_of_buffs.clear() # Hapus semua
	
	# Buat pool baru
	var pool = _get_full_boon_pool(["Cinderella"])
	var new_boons = _get_random_buffs_from_pool(new_buff_count, pool)

	# Tambahkan boon baru
	for new_boon in new_boons:
		list_of_buffs.append(new_boon)
		print("  Boon baru: ", new_boon.boon_name)

func _trade_for_specific():
	print("--- CINDERELLA: Glass Slipper! ---")
	if list_of_buffs.size() > 0:
		var idx = randi_range(0, list_of_buffs.size() - 1)
		var removed_boon = list_of_buffs.pop_at(idx)
		print("  Boon dihapus: ", removed_boon.boon_name)
	
	# TODO: Tampilkan UI Pemilihan Giver
	print("LOGIKA 'GLASS SLIPPER' BELUM DIBUAT (PERLU UI). Memberi 1 boon acak...")
	_gain_random_buffs(1)
	pass
	

func _trade_all_for_hp():
	print("--- CINDERELLA: Rags to Riches! ---")
	# 1. Hitung jumlah boon yang akan ditukar
	var boon_count = list_of_buffs.size()
	
	if boon_count == 0:
		print("...Tidak ada boon untuk ditukar. Dapat +5 HP sebagai hiburan.")
		base_stats.hp += 5 # (Hadiah hiburan)
	else:
		print("Menukar %s boon untuk HP..." % boon_count)
		
		# 2. Hapus semua boon
		list_of_buffs.clear()
		
		# 3. Hitung HP yang didapat
		var hp_gain = boon_count * 2 # (+2 Max HP per boon)
		
		# 4. Tambahkan ke BASE STATS
		# (PENTING: Kita modifikasi 'base_stats', bukan 'current_stats')
		base_stats.hp += hp_gain
		
		# 5. Langsung heal player sejumlah HP yang didapat
		var health_manager = get_parent().get_node("HealthManager")
		if is_instance_valid(health_manager):
			health_manager.heal(hp_gain)
			
	print("HP Max baru: ", base_stats.hp)

func _on_enemy_killed():
	if current_stats.frenzy_duration == 0.0:
		return
		
	for buff in list_of_buffs:
		if buff.buff_type == "FrenzyActive":
			buff.time_left = current_stats.frenzy_duration
			return 

	if frenzy_timer.is_stopped():
		frenzy_kill_count = 0
		frenzy_timer.start()

	frenzy_kill_count += 1
	print("Frenzy kill count: ", frenzy_kill_count)
	
	if frenzy_kill_count >= 3:
		print("HUNTER'S HASTE! FRENZY DIAKTIFKAN!")
		frenzy_timer.stop()
		frenzy_kill_count = 0
		
		var frenzy_buff = BuffBase.new()
		frenzy_buff.buff_type = "FrenzyActive" 
		frenzy_buff.permanent = false
		frenzy_buff.duration = current_stats.frenzy_duration 
		frenzy_buff.time_left = current_stats.frenzy_duration
		
		frenzy_buff.modifier.move_speed = 1.5
		frenzy_buff.modifier.set_mode("move_speed", "multiply")
		frenzy_buff.modifier.final_damage = 1.5
		frenzy_buff.modifier.set_mode("final_damage", "multiply")
		
		list_of_buffs.append(frenzy_buff)
		_calculate_all() 

func _on_frenzy_timer_timeout():
	print("Frenzy timer timeout. Reset kill count.")
	frenzy_kill_count = 0

func _get_full_boon_pool(exclude_givers: Array[String] = []) -> Array[BuffBase]:
	var full_pool: Array[BuffBase] = []
	
	var giver_pool = [BuffRabbit, BuffHood, BuffWizard, BuffPig]
	giver_pool = giver_pool.filter(func(buff_class): return buff_class.new().buff_type not in exclude_givers)
	
	for giver_class in giver_pool:
		for i in 5:
			var boon = giver_class.new()
			boon.boon_type = i 
			boon._generate_boon() 
			full_pool.append(boon)
			
	return full_pool

func _get_random_buffs_from_pool(amount: int, pool: Array[BuffBase]) -> Array[BuffBase]:
	var chosen_boons: Array[BuffBase] = []
	
	# Filter boon yang sudah dimiliki dari pool
	var available_pool = []
	var collected_names = []
	for buff in list_of_buffs:
		collected_names.append(buff.boon_name)
		
	for boon in pool:
		if not boon.boon_name in collected_names:
			available_pool.append(boon)
			
	# Acak pool yang tersedia
	available_pool.shuffle()
	
	# Ambil 'amount'
	for i in range(min(amount, available_pool.size())):
		chosen_boons.append(available_pool[i])
		
	return chosen_boons
