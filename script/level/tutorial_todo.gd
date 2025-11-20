extends VBoxContainer

@export var custom_font: Font
@export var font_size: int = 22
@export var slide_distance: float = 20.0

@onready var dash_manager: DashManager = $"../../../PlayerSpawnPosition/Player/DashManager"
@onready var possession_manager: PossessionManager = $"../../../PlayerSpawnPosition/Player/PossessionManager"
@onready var skill_manager: SkillManager = $"../../../PlayerSpawnPosition/Player/SkillManager"
@onready var super_dash: SuperDash = $"../../../PlayerSpawnPosition/Player/SkillManager/SuperDash"
@onready var morph_skill: Node2D = $"../../../PlayerSpawnPosition/Player/SkillManager/MorphSkill"

var active_tasks: Array = []
var tasks_ref: Dictionary = {}
var spawn_queue: Array = []
var is_spawning: bool = false
var total_expected_tasks: int = 9

func _ready():
	_queue_task(1, "Left click / Space to dash", 
		func(): return dash_manager.is_dashing
	)

func _process(_delta):
	_process_spawn_queue()

	for task in active_tasks:
		if not task.has("ui_node") or task.is_done:
			continue
			
		if task.condition.is_valid() and task.condition.call() == true:
			complete_task_sequence(task)

	_handle_task_progression()

func _handle_task_progression():
	if _is_task_done(1) and not _has_task(2):
		_queue_task(2, "Possess enemy (Dash into enemy)", 
			func(): return possession_manager.is_possessing
		)

	if _is_task_done(2):
		if not _has_task(3):
			_queue_task(3, "Exit dash to damage", 
				func(): return dash_manager.is_exit_dashing or dash_manager.is_exit_moving
			)
		if not _has_task(4):
			_queue_task(4, "Perfect Exit (Timing Circle correctly)", 
				func(): return _is_perfect_exit_condition()
			)

	if _is_task_done(4) and _has_task(3) and not _is_task_done(3):
		complete_task_sequence(tasks_ref[3], true) # true = instant complete

	if _is_task_done(3) and _is_task_done(4):
		if not _has_task(5):
			_queue_task(5, "Cast Pin (Press E)", 
				func(): return skill_manager.pin.is_active() or Input.is_action_just_pressed("pin")
			)
		if not _has_task(6):
			_queue_task(6, "Use Morph Skill (Press Shift)", 
				func(): return morph_skill.is_active()
			)
		if not _has_task(7):
			_queue_task(7, "Do 3 Perfect Circles (0/3)", 
				func(): return _check_super_dash_charge_progress(tasks_ref[7])
			)

	if _is_task_done(5) and not _has_task(8):
		_queue_task(8, "Possess your Pin", 
			func(): 
				var target = possession_manager.possessed_target
				return target != null and target.get_parent() is ThrownPin
		)

	if _is_task_done(7) and not _has_task(9):
		_queue_task(9, "Super Dash (Right Click)", 
			func(): return super_dash.is_dashing
		)

func _queue_task(id: int, text: String, condition: Callable):
	var task_data = {
		"id": id,
		"text": text,
		"condition": condition,
		"is_done": false,
		"ui_node": null
	}
	
	tasks_ref[id] = task_data
	active_tasks.append(task_data)
	
	spawn_queue.append(task_data)

func _process_spawn_queue():
	if is_spawning or spawn_queue.is_empty():
		return
		
	is_spawning = true
	var task_data = spawn_queue.pop_front()
	
	_create_task_ui(task_data)
	
	await get_tree().create_timer(0.2).timeout
	is_spawning = false

func _create_task_ui(task_data: Dictionary):
	var hbox = HBoxContainer.new()
	var checkbox = CheckBox.new()
	var label = RichTextLabel.new()
	
	checkbox.focus_mode = Control.FOCUS_NONE
	checkbox.mouse_filter = Control.MOUSE_FILTER_IGNORE 
	checkbox.disabled = true 
	
	label.text = task_data["text"]
	label.z_index = 1
	label.fit_content = true
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size.y = 30 
	
	if custom_font:
		label.add_theme_font_override("normal_font", custom_font)
	label.add_theme_font_size_override("normal_font_size", font_size)
	
	hbox.add_child(checkbox)
	hbox.add_child(label)
	add_child(hbox)
	
	task_data["ui_node"] = hbox
	task_data["checkbox"] = checkbox
	
	hbox.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(hbox, "modulate:a", 1.0, 0.5)
	
	label.position.y += slide_distance 
	checkbox.position.y += slide_distance 
	tween.tween_property(label, "position:y", label.position.y - slide_distance, 0.5)
	tween.tween_property(checkbox, "position:y", checkbox.position.y - slide_distance, 0.5)



func complete_task_sequence(task: Dictionary, instant_remove: bool = false):
	if task.is_done: return
	
	task.is_done = true
	
	if not task.has("ui_node") or task.ui_node == null:
		_check_all_completed()
		return

	var hbox = task.ui_node
	var checkbox = task.checkbox
	var label = hbox.get_child(1)
	
	checkbox.button_pressed = true
	label.modulate = Color.GREEN
	
	var delay = 1.0 if not instant_remove else 0.1
	
	await get_tree().create_timer(delay).timeout
	
	if not is_instance_valid(hbox): return
	
	var tween_out = create_tween()
	tween_out.set_parallel(true)
	tween_out.set_ease(Tween.EASE_IN)
	tween_out.set_trans(Tween.TRANS_QUAD)
	
	tween_out.tween_property(hbox, "modulate:a", 0.0, 0.5)
	tween_out.tween_property(hbox, "position:x", -50.0, 0.5) # Slide ke kiri
	
	await tween_out.finished
	
	if not is_instance_valid(hbox): return

	hbox.clip_contents = true
		
	var current_height = hbox.size.y
	var tween_shrink = create_tween()
	
	tween_shrink.tween_property(hbox, "custom_minimum_size:y", 0, 0.3).from(current_height)
	
	await tween_shrink.finished
	
	if is_instance_valid(hbox):
		hbox.queue_free()
		task["ui_node"] = null
	
	_check_all_completed()

func _check_all_completed():
	if not spawn_queue.is_empty():
		return
	
	if tasks_ref.size() < total_expected_tasks:
		return
		
	for task_id in tasks_ref:
		var task = tasks_ref[task_id]
		if not task.is_done:
			return

	await get_tree().create_timer(0.5).timeout
	_show_tutorial_completed_text()

func _show_tutorial_completed_text():
	if has_node("TutorialCompleteLabel"): return
	
	var final_label = Label.new()
	final_label.name = "TutorialCompleteLabel"
	final_label.text = "TUTORIAL COMPLETED!"
	
	if custom_font:
		final_label.add_theme_font_override("font", custom_font)
	final_label.add_theme_font_size_override("font_size", 32)
	final_label.modulate = Color.GOLD
	
	add_child(final_label)
	
	final_label.scale = Vector2.ZERO
	final_label.pivot_offset = Vector2(final_label.size.x / 2, final_label.size.y / 2)
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_ELASTIC)
	tween.tween_property(final_label, "scale", Vector2.ONE, 0.8)


func _is_perfect_exit_condition() -> bool:
	var any_skill_ready = skill_manager.homing_shot_ready or \
						  skill_manager.triple_homing_shot_ready or \
						  skill_manager.wolf_morph_ready or \
						  skill_manager.slash_shot_ready
	return any_skill_ready and (dash_manager.is_exit_dashing or dash_manager.is_exit_moving)

func _check_super_dash_charge_progress(task_dict: Dictionary) -> bool:
	if not task_dict.has("ui_node") or task_dict.ui_node == null: return false
	
	var current_charge = super_dash.super_dash_recharge_counter
	var max_charge = super_dash.super_dash_recharge_needed
	var is_fully_charged = super_dash.super_dash_counter == 0
	
	var display_count = current_charge
	if is_fully_charged:
		display_count = max_charge 
	
	_update_label_text(task_dict, "Do 3 Perfect Circles (%d/%d)" % [display_count, max_charge])
	return is_fully_charged

func _update_label_text(task_dict: Dictionary, new_text: String):
	if not task_dict.has("ui_node") or task_dict.ui_node == null: return
	var label = task_dict.ui_node.get_child(1) as RichTextLabel
	if label.text != new_text:
		label.text = new_text

func _has_task(id: int) -> bool:
	return tasks_ref.has(id)

func _is_task_done(id: int) -> bool:
	if tasks_ref.has(id):
		return tasks_ref[id].is_done
	return false
