extends Node2D
class_name SkillManager

@onready var super_dash: SuperDash = $SuperDash
@onready var pin: Pin = $Pin
@onready var homing_shot: HomingShot = $HomingShot
@onready var triple_homing_shot: TripleHomingShot = $TripleHomingShot # TAMBAHAN
@onready var possession_manager: PossessionManager = $"../PossessionManager"
@onready var dash_manager: DashManager = $"../DashManager"
@onready var morph_skill: Node2D = $MorphSkill

var homing_shot_ready : bool = false
var triple_homing_shot_ready : bool = false

func start_or_return_super_dash() :
	super_dash.start_super_dash()

func use_morph_skill() -> void:
	if morph_skill.start_skill(homing_shot_ready, triple_homing_shot_ready) :
		homing_shot_ready = false
		triple_homing_shot_ready = false

func use_pin() -> void:
	pin.throw_pin()

func is_possesing() -> bool :
	return possession_manager.is_possessing

func is_dashing() -> bool :
	return dash_manager.is_dashing

func is_casting_skill() -> bool :
	return super_dash.is_active() or pin.is_active() or morph_skill.is_active()

func add_pin() :
	pin.add_count()

func morph(name:String) :
	if name.begins_with("ShootingEnemy") :
		homing_shot_ready = true
	elif name.begins_with("DashShootingEnemy") :
		triple_homing_shot_ready = true
