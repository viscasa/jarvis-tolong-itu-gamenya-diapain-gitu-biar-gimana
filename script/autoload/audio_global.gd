extends Node

@onready var background_music: AudioStreamPlayer = $BackgroundMusic

var master_volume : int = 0
var music_volume : int = 0
var sfx_volume : int = 0
var music_current_position : float

func _ready() -> void:
	#background_music.play()
	pass

func change_bgm_to_calm() -> void :
	if (background_music["parameters/switch_to_clip"] == "Calm") :
		return
	background_music["parameters/switch_to_clip"] = "Calm"

func change_bgm_to_combat() -> void :
	if (background_music["parameters/switch_to_clip"] == "Combat") :
		return
	background_music["parameters/switch_to_clip"] = "Combat"

func stop_bgm():
	background_music.stop()
func start_sfx(sfx_position:Node, sfx_path:String, pitch_randomizer:Array = [1,1], volume:float = 0, start_at:float = 0) -> void :
	var audio_resource := load(sfx_path)
	var speaker = AudioStreamPlayer2D.new()
	sfx_position.add_child(speaker)
	speaker.stream = audio_resource
	speaker.bus = "SFX"
	speaker.pitch_scale = randf_range(pitch_randomizer[0], pitch_randomizer[1])
	speaker.volume_db = volume
	speaker.play(start_at)
	await speaker.finished
	speaker.queue_free()

#func update_volume() -> void :
	#var master_index = AudioServer.get_bus_index("Master")
	#var music_index = AudioServer.get_bus_index("Music")
	#var sfx_index = AudioServer.get_bus_index("SFX")
	#
	#AudioServer.set_bus_volume_db(master_index, master_volume)
	#AudioServer.set_bus_volume_db(master_index, music_volume)
	#AudioServer.set_bus_volume_db(sfx_index, sfx_volume)
	
## decible normally is 0
## pitch normally is 1
#func play_audio(path_to_file: String, decible := 0.0 , pitch := 1.0):
	#var usable_audios_children = _usable_audios.get_children()
	#var audio_resource := load(path_to_file)
	#for speaker in usable_audios_children:
		#if not speaker.playing:
			#speaker.pitch_scale = pitch
			#speaker.volume_db = decible
			#speaker.stream = audio_resource
			#speaker.play()
#
## Call on player move
## enable_shift is used to make walking sound not monotonous
#func play_walk_audio(enable_shift := true):
	#if _dedicated_walk_audio_player.playing:
		#return
	#if enable_shift:
		#_dedicated_walk_audio_player.pitch_scale = randf_range(0.7,1.3)
		#_dedicated_walk_audio_player.volume_db = randf_range(-0.8, 0.8)
	#_dedicated_walk_audio_player.play()
#
## Use this to play background audios
#func play_background_audio(path_to_file: String, decible := 0.0):
	#var audio_resource := load(path_to_file)
	#if _dedicated_walk_audio_player.playing:
		## fade out audio
		#var tween := create_tween()
		#tween.tween_property(_dedicated_background_audio_player, "volume_db", -30.0, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		#await tween.finished
		#_dedicated_walk_audio_player.volume_db = decible
		#_dedicated_background_audio_player.stream = audio_resource
		#_dedicated_background_audio_player.play()
		#tween = create_tween()
		##fade in audio
		#tween.tween_property(_dedicated_background_audio_player, "volume_db", decible, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		#await tween.finished
		#return
	#_dedicated_walk_audio_player.volume_db = decible
	#_dedicated_background_audio_player.stream = audio_resource
	#_dedicated_background_audio_player.play()
