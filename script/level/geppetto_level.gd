extends Node2D

@export var player: Player
@export var geppetto: Geppetto
@export var camera: Camera2D

func _ready():
	
	AudioManager.stop_bgm()
	if not is_instance_valid(player) or not is_instance_valid(geppetto) or not is_instance_valid(camera):
		push_warning("Player, Geppetto, or Camera not assigned in GeppettoLevel script.")
		return
		
	_start_boss_intro()

func _start_boss_intro():
	GlobalVar.input_disabled = true
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(camera, "global_position", geppetto.global_position + Vector2(20, -70), 1.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(camera, "zoom", Vector2(1.8, 1.8), 1.5).set_trans(Tween.TRANS_SINE)
	
	await tween.finished
	
	await geppetto.play_summon_animation_only()
	await get_tree().create_timer(0.2).timeout
	
	await geppetto.perform_initial_spawn()
	
	var return_tween = create_tween()
	return_tween.set_parallel(true)
	return_tween.tween_property(camera, "global_position", player.global_position, 1.0).set_trans(Tween.TRANS_SINE)
	return_tween.tween_property(camera, "zoom", Vector2(1.5, 1.5), 1.0).set_trans(Tween.TRANS_SINE)
	
	await return_tween.finished
	GlobalVar.input_disabled = false
	geppetto.start_combat()
