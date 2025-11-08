extends Node
class_name player_buff_manager

@export var base_stats: PlayerModifier = PlayerModifier.new() # base stats for player
var current_stats: PlayerModifier = PlayerModifier.new()
var list_of_buffs: Array[BuffBase] = []

signal buffs_updated(current_stats: PlayerModifier)

func _ready():
	# Initialize base stats (example values)
	base_stats.hp = 100
	_calculate_all()

func add_buff(buff: BuffBase):
	if buff.buff_type == "Cinderella":
		_handle_cinderella_effect(buff)
	else:
		list_of_buffs.append(buff)
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
	var total_modifier := PlayerModifier.new()
	for buff in list_of_buffs:
		total_modifier = total_modifier.add(buff.modifier)
	current_stats = base_stats.add(total_modifier)
	emit_signal("buffs_updated", current_stats)

func _process(delta: float) -> void:
	for buff in list_of_buffs:
		buff.update(delta)
	remove_expired_buffs()
	
func _create_random_buff(exclude: Array[String] = []) -> BuffBase:
	var pool = [BuffRabbit, BuffHood, BuffWizard, BuffPig]
	# Filter out excluded buff types
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
			_gain_random_buffs(5)
		3:
			_reroll_all_buffs()
	remove_buff(buff.buff_type)

func _trade_and_gain_buffs(trade_count: int, gain_count: int):
	# Remove random existing buff(s)
	for i in range(trade_count):
		if list_of_buffs.size() > 0:
			var idx = randi_range(0, list_of_buffs.size() - 1)
			list_of_buffs.remove_at(idx)

	# Add random new ones
	for i in range(gain_count):
		var new_buff = _create_random_buff()
		list_of_buffs.append(new_buff)

	_calculate_all()

func _gain_random_buffs(amount: int):
	for i in range(amount):
		list_of_buffs.append(_create_random_buff())
	_calculate_all()

func _reroll_all_buffs():
	var new_buff_count = list_of_buffs.size()
	list_of_buffs.clear()

	# Maybe give some random fresh buffs
	
	for i in range(new_buff_count):
		list_of_buffs.append(_create_random_buff())

	_calculate_all()
