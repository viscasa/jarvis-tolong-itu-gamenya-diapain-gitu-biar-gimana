extends Area2D
class_name Hurtbox

signal player_possessed
signal player_auto_exit

var cooldown_possessed:float = 1.5
@onready var circle: Node2D = $Circle
@onready var circle_animation: AnimationPlayer = $Circle/CircleAnimation

func _ready():
	area_entered.connect(_on_area_entered)
	connect("body_entered", Callable(self, "_on_body_entered"))

func _on_area_entered(area):
	if !circle :
		return
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
		circle_animation.stop()
		circle_animation.play("shrink_in")
		pm.possess(self)
		emit_signal("player_possessed")
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
			var hit_direction = (get_parent().global_position - area.global_position).normalized()
			stats_node.take_damage(area.damage, hit_direction)
		else:
			print("ERROR: " + get_parent().name + " tidak punya node Stats!")

func auto_exit() -> void:
	emit_signal("player_auto_exit")
	circle_animation.stop()
	circle_animation.play("shrink_in")
	circle_animation.advance(0.76)
	await circle_animation.animation_finished
	circle_animation.play("fade_out")
	await circle_animation.animation_finished

func exit() -> void:
	circle_animation.play("fade_out")
	await circle_animation.animation_finished

func get_current_circle_time() -> float:
	return circle_animation.current_animation_position
