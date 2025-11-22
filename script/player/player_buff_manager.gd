extends Node

@export var base_stats: PlayerModifier = PlayerModifier.new() 
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
	
	if buff.buff_type == "Cinderella":
		_handle_cinderella_effect(buff)
		
	elif buff.buff_type == "Pig" and buff.modifier.ressurection == 9999: 
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			var health_manager = player.get_node_or_null("HealthManager")
			if is_instance_valid(health_manager):
				health_manager.heal(health_manager.max_health - health_manager.current_health)
	
	else:
		list_of_buffs.append(buff)
		RewardManager.register_boon_as_collected(buff)
		_calculate_all() 

func remove_buff(buff_type: String):
	list_of_buffs = list_of_buffs.filter(func(b): return b.buff_type != buff_type)
	_calculate_all()

func remove_expired_buffs():
	var before := list_of_buffs.size()
	list_of_buffs = list_of_buffs.filter(func(b): return b.duration == 0 or b.time_left > 0)
	if before != list_of_buffs.size():
		_calculate_all()

func _calculate_all():
	var new_stats = base_stats 
	
	for buff in list_of_buffs:
		new_stats = new_stats.apply_modifier(buff.modifier)
		
	current_stats = new_stats
	
	emit_signal("buffs_updated", current_stats)

func _process(delta: float) -> void:
	var needs_recalc = false
	for buff in list_of_buffs:
		if not buff.permanent:
			buff.update(delta)
			if buff.time_left == 0:
				needs_recalc = true
	
	if needs_recalc:
		remove_expired_buffs()
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
			_trade_and_gain_buffs(1, 3) 
		2:
			_trade_all_for_evasion()
		3:
			_reroll_all_buffs()
		4:
			_trade_all_for_hp() 
		5:
			_gain_random_buffs(2) 
	
	_calculate_all() 

func _trade_and_gain_buffs(trade_count: int, gain_count: int):
	for i in range(trade_count):
		if list_of_buffs.size() > 0:
			var idx = randi_range(0, list_of_buffs.size() - 1)
			var removed_boon = list_of_buffs.pop_at(idx)
			RewardManager.unregister_boon_by_name(removed_boon.boon_name) # ← HARUS DITAMBAHKAN
			
	_gain_random_buffs(gain_count) 

func _gain_random_buffs(amount: int):
	var pool = _get_full_boon_pool(["Cinderella"])
	var new_boons = _get_random_buffs_from_pool(amount, pool)
	
	if new_boons.is_empty():
		return
	for new_boon in new_boons:
		list_of_buffs.append(new_boon)
		RewardManager.register_boon_as_collected(new_boon)

func _reroll_all_buffs():
	var new_buff_count = list_of_buffs.size()
	
	for old_boon in list_of_buffs:
		RewardManager.unregister_boon_by_name(old_boon.boon_name)
	list_of_buffs.clear()
	
	var pool = _get_full_boon_pool(["Cinderella"])
	var new_boons = _get_random_buffs_from_pool(new_buff_count, pool)

	for new_boon in new_boons:
		list_of_buffs.append(new_boon)
		# FIX: Daftarkan kembali boon baru yang didapat dari reroll
		RewardManager.register_boon_by_name(new_boon.boon_name)
		print("  Boon baru (reroll): ", new_boon.boon_name)


	

func _trade_all_for_hp():
	var boon_count = list_of_buffs.size()
	
	for boon in list_of_buffs:
		RewardManager.unregister_boon_by_name(boon.boon_name) # ← HARUS DITAMBAHKAN
	list_of_buffs.clear()
	
	if boon_count != 0:
		list_of_buffs.clear()
		
		var hp_gain = boon_count * 30
		
		base_stats.hp += hp_gain
		
		var player = get_tree().get_first_node_in_group("player")
		if is_instance_valid(player):
			var health_manager = player.get_node_or_null("HealthManager")
			if is_instance_valid(health_manager):
				health_manager.heal(hp_gain)
			

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
	
	if frenzy_kill_count >= 3:
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
	
	# FIX: Hanya gunakan daftar dari RewardManager. Ini adalah satu-satunya sumber kebenaran.
	var collected_names = RewardManager.get_collected_boon_names()
		
	var available_pool = []
	for boon in pool:
		if not boon.boon_name in collected_names:
			available_pool.append(boon)
			
	available_pool.shuffle()
	
	for i in range(min(amount, available_pool.size())):
		chosen_boons.append(available_pool[i])
		
	return chosen_boons
func _trade_all_for_evasion():
	
	
	var boon_count = list_of_buffs.size()
	
	for boon in list_of_buffs:
		RewardManager.unregister_boon_by_name(boon.boon_name) # ← HARUS DITAMBAHKAN
	list_of_buffs.clear()
	
	if boon_count != 0:
		list_of_buffs.clear()
		
		var evasion_gain = float(boon_count) * 0.02
		
		base_stats.evasion_chance += evasion_gain
			
func reset_all_buffs():
	list_of_buffs.clear()
	base_stats = PlayerModifier.new()
	
	_calculate_all()
	
	RewardManager.reset_collected_boons()
func consume_resurrection():
	for i in range(list_of_buffs.size()):
		var boon = list_of_buffs[i]
		if boon.modifier.ressurection > 0:
			print("Consuming resurrection boon: ", boon.boon_name)
			list_of_buffs.remove_at(i) 
			_calculate_all() 
			return
