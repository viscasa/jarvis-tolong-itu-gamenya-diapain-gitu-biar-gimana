extends Area2D
class_name Hurtbox

var cooldown_possessed:float = 1.5

func _ready():
	area_entered.connect(_on_area_entered)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_area_entered(area):
	if not area.get_parent() is Player:
		return
	var player = area.get_parent()
	var dm = player.get_node("DashManager")
	var pm = player.get_node("PossessionManager")

	var allowed := false
	allowed = dm.is_dashing or dm.is_exit_dashing

	if allowed and not dm.auto_exit_possess_lock:
		set_collision_layer_value(1,false)
		set_collision_mask_value(1,false)
		pm.possess(self)
		await dm.exit_cycle_started
		await get_tree().create_timer(cooldown_possessed).timeout
		set_collision_layer_value(1,true)
		set_collision_mask_value(1,true)
		
	# 1. Cek apakah yang masuk adalah sebuah Hitbox
	if area is Hitbox:
		# 2. Cari node 'Stats' yang seharusnya ada di parent kita
		# (Struktur: Player/Hurtbox dan Player/Stats)
		var stats_node = get_parent().get_node_or_null("Stats")
		
		if stats_node:
			# 3. Panggil fungsi 'take_damage' di Stats dan kirim damage-nya
			stats_node.take_damage(area.damage)
		else:
			print("ERROR: " + get_parent().name + " tidak punya node Stats!")
			
