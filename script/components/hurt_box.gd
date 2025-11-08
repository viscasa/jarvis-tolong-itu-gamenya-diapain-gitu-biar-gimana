extends Area2D
class_name Hurtbox

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
	if dm.must_exit_before_possession:
		allowed = dm.has_exited_since_last_possession
	else:
		# Gerak atau masih dalam jendela siklus
		allowed = dm.is_dashing or dm.is_exit_dashing or dm.dash_cycle_active or dm.exit_dash_cycle_active

	if allowed:
		pm.possess(self)
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
			
