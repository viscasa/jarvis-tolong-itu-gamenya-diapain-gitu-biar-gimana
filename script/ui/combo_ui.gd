extends CanvasLayer

@onready var label: Label = $ComboLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var reset_timer: Timer = $ResetTimer
@onready var player: Player = $".."
@onready var timer_bar: ProgressBar = $TimerBar
@onready var circle_timing: Node2D = $"../CircleTiming"
@export var health_manager: HealthManager
@export var max_combo_time: float = 0.76

@export var bar_color_normal: Color = Color(0.2, 0.8, 1.0) 
@export var bar_color_warning: Color = Color(1.0, 0.5, 0.2) 
@export var bar_color_critical: Color = Color(1.0, 0.2, 0.2) 

var possession_manager: PossessionManager
var dash_manager: DashManager
var current_combo: int = 0
var is_resetting: bool = false

func _ready():
	_setup_ui()
	_setup_timers()
	_setup_managers()

func _setup_ui():
	label.hide()
	
	if timer_bar:
		timer_bar.hide()
		timer_bar.max_value = max_combo_time
		timer_bar.value = max_combo_time
		timer_bar.show_percentage = false
	
	if not animation_player:
		animation_player = AnimationPlayer.new()
		animation_player.name = "AnimationPlayer"
		add_child(animation_player)
	_setup_animations()

func _setup_timers():
	if not reset_timer:
		reset_timer = Timer.new()
		reset_timer.name = "ResetTimer"
		reset_timer.one_shot = true
		add_child(reset_timer)
	
	reset_timer.wait_time = max_combo_time
	reset_timer.timeout.connect(_reset_combo)

func _setup_managers():
	if not player:
		push_error("ComboUI: Player node not found!")
		return
	
	possession_manager = player.get_node_or_null("PossessionManager")
	dash_manager = player.get_node_or_null("DashManager")
	circle_timing = player.get_node_or_null("CircleTiming") 
	
	if possession_manager:
		possession_manager.possessed.connect(_on_possess_started)
		
	if dash_manager:
		if not dash_manager.dash_movement_started.is_connected(_reset_combo):
			dash_manager.dash_movement_started.connect(_reset_combo)
			
		if not dash_manager.auto_exit_dash_started.is_connected(_reset_combo):
			dash_manager.auto_exit_dash_started.connect(_reset_combo)
	
	if circle_timing:
		circle_timing.exit_missed.connect(_reset_combo)
	
	if health_manager:
		if not health_manager.no_health.is_connected(_reset_combo):
			health_manager.no_health.connect(_reset_combo)
func _on_possess_started(target_hurtbox: Node):
	if is_resetting:
		return
	var target_owner = target_hurtbox.get_parent()

	if target_owner is ThrownPin:
		_on_pin_possessed()
	else:
		_on_enemy_possessed()
func _on_enemy_possessed():
	current_combo += 1
	_update_combo_display()
	
	reset_timer.start(max_combo_time)
	
	if timer_bar:
		if (current_combo > 1):
			timer_bar.show()
		timer_bar.value = max_combo_time
		timer_bar.modulate = bar_color_normal
	
	if animation_player:
		animation_player.play("pop_in")

func _on_pin_possessed():
	if current_combo > 0:
		reset_timer.start(max_combo_time)
		
		if animation_player:
			animation_player.play("pop_in")
			
func _physics_process(_delta):
	if timer_bar and not reset_timer.is_stopped():
		timer_bar.value = reset_timer.time_left
		
		var time_ratio = reset_timer.time_left / max_combo_time
		if time_ratio > 0.5:
			timer_bar.modulate = bar_color_normal
		elif time_ratio > 0.25:
			timer_bar.modulate = bar_color_warning
		else:
			timer_bar.modulate = bar_color_critical

func _on_combo_success():
	if is_resetting:
		return
	
	current_combo += 1
	
	_update_combo_display() 
	
	reset_timer.start(max_combo_time)
	
	if timer_bar:
		if current_combo > 1:
			timer_bar.show()
		
		timer_bar.value = max_combo_time
		timer_bar.modulate = bar_color_normal
	
	if animation_player:
		animation_player.play("pop_in")

func _update_combo_display():
	label.text = "CHAIN x%d" % current_combo
	if current_combo > 1:
		label.show()

func _reset_combo():
	if current_combo == 0:
		return
	
	is_resetting = true
	
	
	if animation_player and animation_player.has_animation("pop_out"):
		animation_player.play("pop_out")
	else:
		label.hide()
	
	if timer_bar:
		timer_bar.hide()
	
	current_combo = 0
	reset_timer.stop()
	
	await get_tree().create_timer(0.1).timeout
	is_resetting = false

func _setup_animations():
	var anim_lib = AnimationLibrary.new()
	
	var anim_pop_in = Animation.new()
	anim_pop_in.length = 0.5
	
	var track_scale = anim_pop_in.add_track(Animation.TYPE_VALUE)
	anim_pop_in.track_set_path(track_scale, "ComboLabel:scale")
	anim_pop_in.track_insert_key(track_scale, 0.0, Vector2(0.5, 0.5))
	anim_pop_in.track_insert_key(track_scale, 0.15, Vector2(1.3, 1.3))
	anim_pop_in.track_insert_key(track_scale, 0.3, Vector2(0.95, 0.95))
	anim_pop_in.track_insert_key(track_scale, 0.4, Vector2(1.0, 1.0))
	anim_pop_in.track_set_interpolation_type(track_scale, Animation.INTERPOLATION_CUBIC)
	
	var track_opacity = anim_pop_in.add_track(Animation.TYPE_VALUE)
	anim_pop_in.track_set_path(track_opacity, "ComboLabel:modulate:a")
	anim_pop_in.track_insert_key(track_opacity, 0.0, 0.0)
	anim_pop_in.track_insert_key(track_opacity, 0.2, 1.0)
	
	var anim_pop_in_big = Animation.new()
	anim_pop_in_big.length = 0.6
	
	var track_scale_big = anim_pop_in_big.add_track(Animation.TYPE_VALUE)
	anim_pop_in_big.track_set_path(track_scale_big, "ComboLabel:scale")
	anim_pop_in_big.track_insert_key(track_scale_big, 0.0, Vector2(0.3, 0.3))
	anim_pop_in_big.track_insert_key(track_scale_big, 0.2, Vector2(1.5, 1.5))
	anim_pop_in_big.track_insert_key(track_scale_big, 0.4, Vector2(0.9, 0.9))
	anim_pop_in_big.track_insert_key(track_scale_big, 0.5, Vector2(1.1, 1.1))
	anim_pop_in_big.track_insert_key(track_scale_big, 0.6, Vector2(1.0, 1.0))
	anim_pop_in_big.track_set_interpolation_type(track_scale_big, Animation.INTERPOLATION_CUBIC)
	
	var track_opacity_big = anim_pop_in_big.add_track(Animation.TYPE_VALUE)
	anim_pop_in_big.track_set_path(track_opacity_big, "ComboLabel:modulate:a")
	anim_pop_in_big.track_insert_key(track_opacity_big, 0.0, 0.0)
	anim_pop_in_big.track_insert_key(track_opacity_big, 0.25, 1.0)
	
	var anim_pop_out = Animation.new()
	anim_pop_out.length = 0.4
	
	var track_scale_out = anim_pop_out.add_track(Animation.TYPE_VALUE)
	anim_pop_out.track_set_path(track_scale_out, "ComboLabel:scale")
	anim_pop_out.track_insert_key(track_scale_out, 0.0, Vector2(1.0, 1.0))
	anim_pop_out.track_insert_key(track_scale_out, 0.4, Vector2(0.5, 0.5))
	anim_pop_out.track_set_interpolation_type(track_scale_out, Animation.INTERPOLATION_CUBIC)
	
	var track_opacity_out = anim_pop_out.add_track(Animation.TYPE_VALUE)
	anim_pop_out.track_set_path(track_opacity_out, "ComboLabel:modulate:a")
	anim_pop_out.track_insert_key(track_opacity_out, 0.0, 1.0)
	anim_pop_out.track_insert_key(track_opacity_out, 0.3, 0.0)
	
	var track_method = anim_pop_out.add_track(Animation.TYPE_METHOD)
	anim_pop_out.track_set_path(track_method, "ComboLabel")
	anim_pop_out.track_insert_key(track_method, 0.4, {"method": "hide", "args": []})
	
	anim_lib.add_animation("pop_in", anim_pop_in)
	anim_lib.add_animation("pop_in_big", anim_pop_in_big)
	anim_lib.add_animation("pop_out", anim_pop_out)
	animation_player.add_animation_library("", anim_lib)

func get_current_combo() -> int:
	return current_combo

func force_reset():
	_reset_combo()

func set_combo_time(time: float):
	max_combo_time = time
	reset_timer.wait_time = time
	if timer_bar:
		timer_bar.max_value = time
