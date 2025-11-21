extends CharacterBody2D
class_name Player

const SCALE_UP = 1.7
const SPEED = 150.0 * SCALE_UP
const Y_MUL = 2
const Y_MUL_DASH = 1.7
const ACCELERATION = 600.0 * SCALE_UP

const DASH_SPEED = 600.0  * SCALE_UP
const EXIT_DASH_SPEED = 120.0 * SCALE_UP

@onready var dash_manager: DashManager = $DashManager
@onready var possession_manager: PossessionManager = $PossessionManager
@onready var skill_manager: Node2D = $SkillManager


@onready var super_dash: SuperDash = $SkillManager/SuperDash
@onready var pin: Pin = $SkillManager/Pin
@onready var morph_skill: Node2D = $SkillManager/MorphSkill
@onready var homing_shot: HomingShot = $SkillManager/HomingShot
@onready var triple_homing_shot: TripleHomingShot = $SkillManager/TripleHomingShot
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var possess_area: Area2D = $PossessArea
@onready var hurt_box_player: HurtboxPlayer = $HurtBoxPlayer
@onready var health_manager: HealthManager = $HealthManager
@onready var attack_manager: AttackManager = $AttackManager 
@onready var circle_timing: Node2D = $CircleTiming
@onready var phasing_ray: RayCast2D = $Raycast/PhasingRay
@onready var raycast: Node2D = $Raycast
@onready var camera: Camera2D = $Camera2D
@onready var indicator: Node2D = $Indicator
signal possessed(target)
@onready var knockback_timer: Timer = $KnockbackTimer
@export var knockback_strength: float = 300.0
var is_in_knockback: bool = false
var is_locked_out := false
var last_move_direction := Vector2.DOWN
var is_throwing_pin := false
var is_throwing_pin_first := true
var input_disabled := false
var input_direction := Vector2.ZERO # FIX: Deklarasikan variabel di sini


func _ready() -> void:
	
	add_to_group("player")
	
	sprite.animation_finished.connect(_on_animation_finished) 
	
	dash_manager.player = self
	
	possession_manager.player = self
	possession_manager.possessed.connect(_on_possessed)

	super_dash.player = self
	super_dash.dash_manager = dash_manager
	
	pin.player = self
	pin.dash_manager = dash_manager
	pin.super_dash = super_dash
	
	dash_manager.super_dash = super_dash
	dash_manager.pin = pin
	
	PlayerBuffManager.buffs_updated.connect(_on_buffs_updated)
	_on_buffs_updated(PlayerBuffManager.base_stats)
	health_manager.no_health.connect(_on_player_died)
	skill_manager.stolen_skill_used.connect(_on_stolen_skill_used)
	
	if phasing_ray:
		phasing_ray.set_collision_mask_value(1, true) 
		phasing_ray.enabled = true
		
	health_manager.player_was_hit.connect(_on_was_hit)
	knockback_timer.timeout.connect(_on_knockback_timeout)
	
func _on_buffs_updated(new_stats: PlayerModifier):
	
	health_manager.max_health = new_stats.hp
	
	dash_manager.dash_move_time = new_stats.dash_duration
	
	super_dash.super_dash_recharge_needed = 3 + new_stats.super_dash_cost
	super_dash.aoe_radius = (50.0 * SCALE_UP) * new_stats.explosion_size
	super_dash.aoe_damage = 50.0 * new_stats.explosion_damage # (Damage dasar 50)
	
	var base_crit_start = 0.63
	var base_crit_end = 0.76
	circle_timing.crit_interval[0] = base_crit_start - (new_stats.possesian_timing / 2.0)
	circle_timing.crit_interval[1] = base_crit_end + (new_stats.possesian_timing / 2.0)
	
		
func _on_player_died(): #TODO
	get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	indicator.look_at(get_global_mouse_position())
	if is_in_knockback:
		velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		move_and_slide()
		return 
	dash_manager.update_cooldown(delta)
	
	super_dash.process_super_dash(delta)
	pin._process(delta) 
	morph_skill._process(delta) 

	if not is_locked_out:
		handle_global_inputs()

	if possession_manager.is_possessing:
		possession_manager.process_possession(delta)
	elif super_dash.is_charging:
		_set_super_dash_charge_velocity()
	elif super_dash.is_dashing:
		_set_super_dash_move_velocity()
	elif dash_manager.is_dash_moving:
		_set_dash_velocity()
	elif dash_manager.is_exit_moving:
		_set_exit_dash_velocity()
	elif morph_skill.is_dashing:
		_set_morph_dash_velocity()
	else:
		_process_movement(delta)

	_update_animation_state()

	move_and_slide()

	if dash_manager.is_dash_moving:
		dash_manager.process_dash(delta)
		if not dash_manager.is_dash_moving:
			velocity *= 0.3
	elif dash_manager.is_exit_moving:
		dash_manager.process_exit_dash(delta)
		if not dash_manager.is_exit_moving:
			velocity *= 0.3

func _set_dash_velocity():
	var speed_factor = dash_manager.get_dash_speed_factor()
	var current_dash_speed = DASH_SPEED * speed_factor
	velocity.x = dash_manager.dash_direction.x * current_dash_speed
	velocity.y = dash_manager.dash_direction.y * current_dash_speed / Y_MUL_DASH
	last_move_direction = dash_manager.dash_direction 

func _set_exit_dash_velocity():
	var speed_factor = dash_manager.get_exit_dash_speed_factor()
	var base_exit_speed = dash_manager.current_exit_speed
	var current_speed = base_exit_speed * speed_factor
	velocity.x = dash_manager.exit_dash_direction.x * current_speed
	velocity.y = dash_manager.exit_dash_direction.y * current_speed / Y_MUL_DASH
	last_move_direction = dash_manager.exit_dash_direction 

func _set_super_dash_charge_velocity():
	var vel = super_dash.get_charge_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _set_super_dash_move_velocity():
	var vel = super_dash.get_dash_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _set_morph_dash_velocity():
	var vel = morph_skill.get_dash_velocity()
	if vel.length_squared() > 0.0:
		last_move_direction = vel.normalized()
	velocity.x = vel.x
	velocity.y = vel.y / Y_MUL_DASH

func _process_movement(delta: float) -> void:
	if super_dash.is_active() or morph_skill.is_active():
		velocity = Vector2.ZERO
		return

	var input_vector := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	)
	var current_speed = PlayerBuffManager.current_stats.move_speed
	
	if input_vector.length() > 0.0:
		last_move_direction = input_vector.normalized()
	
	var target_velocity = Vector2.ZERO
	if input_vector.length() > 0.0:
		target_velocity.x = input_vector.normalized().x * current_speed
		target_velocity.y = input_vector.normalized().y * current_speed / Y_MUL
	velocity = velocity.move_toward(target_velocity, ACCELERATION * delta)

func can_start_possession() -> bool:
	if dash_manager.must_exit_before_possession and not dash_manager.has_exited_since_last_possession:
		return false
	return true

func handle_global_inputs() -> void:
	if Input.is_action_just_pressed("super_dash") and not possession_manager.is_possessing:
		if can_start_possession():
			skill_manager.start_or_return_super_dash()
	
	elif Input.is_action_just_pressed("dash") and not possession_manager.is_possessing:
		if can_start_possession():
			dash_manager.start_dash()
	
	elif Input.is_action_just_pressed("pin") and not possession_manager.is_possessing:
		if can_start_possession():
			
			if is_throwing_pin:
				return 
			
			var can_throw_pin = true
			if pin.reload_timer > 0.0:
				can_throw_pin = false
			if pin.current_pins <= 0:
				can_throw_pin = false
			if dash_manager.is_dashing or dash_manager.is_dash_moving or \
			dash_manager.is_exit_dashing or dash_manager.is_exit_moving or \
			super_dash.is_active() or morph_skill.is_active():
				can_throw_pin = false
			
			if can_throw_pin:
				is_throwing_pin = true 
				skill_manager.use_pin()
			
			
	elif Input.is_action_just_pressed("morph_skill") and not possession_manager.is_possessing: 
		if can_start_possession():
			skill_manager.use_morph_skill()

func _on_possessed(target):
	emit_signal("possessed", target)

func lock_actions_during_weak_exit(duration: float) -> void:
	if is_locked_out:
		return
	is_locked_out = true
	await get_tree().create_timer(duration).timeout
	is_locked_out = false

func morph(_name:String) :
	skill_manager.morph(_name)

func start_invisible(time:float = 0) :
	immune_damage(true)
	set_collision_mask_value(1, false)
	if time != 0 :
		await get_tree().create_timer(time).timeout
		end_invisible()

func end_invisible() :
	immune_damage(false)
	hurt_box_player.set_collision_layer_value(2, true)
	set_collision_mask_value(1, true)
	
func immune_damage(flag:bool) :
	hurt_box_player.set_collision_layer_value(2, !flag)

func _update_animation_state() -> void:
	var anim_prefix = "Idle" 
	var anim_direction = last_move_direction 

	if is_throwing_pin:
		if !is_throwing_pin_first :
			return
		is_throwing_pin_first = false
		anim_prefix = "Cast" 
		anim_direction = last_move_direction
	
	elif possession_manager.is_possessing:
		if velocity.length() > 1.0:
			anim_prefix = "Idle" 
			anim_direction = velocity.normalized()
		else:
			anim_prefix = "Idle" 
			anim_direction = last_move_direction
	
	elif super_dash.is_charging:
		anim_prefix = "Charge" 
		var charge_vel = super_dash.get_charge_velocity()
		if charge_vel.length_squared() > 0.0:
			anim_direction = charge_vel.normalized()*-1
		else:
			anim_direction = last_move_direction*-1
	
	elif super_dash.is_dashing or morph_skill.is_dashing or dash_manager.is_dash_moving or dash_manager.is_exit_moving:
		anim_prefix = "Dash"
		if super_dash.is_dashing:
			anim_direction = super_dash.get_dash_velocity().normalized()
		elif morph_skill.is_dashing:
			anim_direction = morph_skill.get_dash_velocity().normalized()
		elif dash_manager.is_dash_moving:
			anim_direction = dash_manager.dash_direction
		else: 
			anim_direction = dash_manager.exit_dash_direction
	
	elif velocity.length() > 1.0: 
		anim_prefix = "Run" 
		anim_direction = velocity.normalized() 
	
	if anim_direction.length_squared() > 0:
		possess_area.rotation = anim_direction.angle()

	_play_directional_animation(anim_prefix, anim_direction)


func _play_directional_animation(prefix: String, direction: Vector2) -> void:
	var suffix := _get_direction_suffix(direction)
	var anim_name = "%s_%s" % [prefix, suffix]
	
	if sprite.animation != anim_name:
		sprite.play(anim_name)


func _get_direction_suffix(direction: Vector2) -> String:
	var angle = direction.angle()
	
	if abs(angle) <= PI / 8.0:
		return "E"
	elif angle > PI / 8.0 and angle <= 3.0 * PI / 8.0:
		return "SE"
	elif angle > 3.0 * PI / 8.0 and angle <= 5.0 * PI / 8.0:
		return "S"
	elif angle > 5.0 * PI / 8.0 and angle <= 7.0 * PI / 8.0:
		return "SW"
	elif abs(angle) > 7.0 * PI / 8.0:
		return "W"
	elif angle < -5.0 * PI / 8.0 and angle >= -7.0 * PI / 8.0:
		return "NW"
	elif angle < -3.0 * PI / 8.0 and angle >= -5.0 * PI / 8.0:
		return "N"
	elif angle < -PI / 8.0 and angle >= -3.0 * PI / 8.0:
		return "NE"
	
	return "S"




func _on_animation_finished() -> void:
	if sprite.animation.begins_with("Cast") :
		is_throwing_pin_first = true
		is_throwing_pin = false
	if is_throwing_pin:
		is_throwing_pin_first = true
		is_throwing_pin = false

func _on_stolen_skill_used():
	var stats = PlayerBuffManager.current_stats
	
	if stats.shield_on_skill_use > 0:
		health_manager.add_shield(stats.shield_on_skill_use)
func _on_was_hit(direction: Vector2):
	if dash_manager.is_dashing or super_dash.is_dashing or morph_skill.is_dashing:
		return
	if is_in_knockback: 
		return
	is_in_knockback = true
	velocity = direction * knockback_strength
	knockback_timer.start()

func _on_knockback_timeout():
	is_in_knockback = false

func get_input():
	if input_disabled:
		input_direction = Vector2.ZERO
		return
		
	input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
