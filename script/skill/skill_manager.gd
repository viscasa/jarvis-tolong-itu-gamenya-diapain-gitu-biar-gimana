extends Node2D
class_name SkillManager

@onready var super_dash: SuperDash = $SuperDash
@onready var pin: Pin = $Pin
@onready var homing_shot: HomingShot = $HomingShot
@onready var triple_homing_shot: TripleHomingShot = $TripleHomingShot # TAMBAHAN
@onready var possession_manager: PossessionManager = $"../PossessionManager"
@onready var dash_manager: DashManager = $"../DashManager"

var current_morph_skill : String = ""

func start_or_return_super_dash() :
	super_dash.start_super_dash()

func use_morph_skill() -> void:
	print(current_morph_skill)
	match current_morph_skill:
		"": 
			pass
		"ShootingEnemy":
			if use_homing_shot():
				current_morph_skill = ""
		"DashShootingEnemy":
			if use_triple_homing_shot():
				current_morph_skill = ""

func use_pin() -> void:
	pin.throw_pin()

func use_homing_shot() -> bool:
	return homing_shot.start_skill()

func use_triple_homing_shot() -> bool:
	return triple_homing_shot.start_skill()

func is_possesing() -> bool :
	return possession_manager.is_possessing

func is_dashing() -> bool :
	return dash_manager.is_dashing

func is_casting_skill() -> bool :
	return super_dash.is_active() or pin.is_active() or homing_shot.is_active() or triple_homing_shot.is_active()

func add_pin() :
	pin.add_count()

func morph(name:String) :
	if name.begins_with("ShootingEnemy") :
		current_morph_skill = "ShootingEnemy"
	elif name.begins_with("DashShootingEnemy") :
		current_morph_skill = "DashShootingEnemy"
