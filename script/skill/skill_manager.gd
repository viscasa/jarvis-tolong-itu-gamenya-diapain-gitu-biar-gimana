extends Node2D
class_name SkillManager

@onready var super_dash: SuperDash = $SuperDash
@onready var pin: Pin = $Pin
@onready var homing_shot: HomingShot = $HomingShot
@onready var triple_homing_shot: TripleHomingShot = $TripleHomingShot
@onready var slash_shot: SlashShot = $SlashShot # <-- TAMBAHAN
@onready var possession_manager: PossessionManager = $"../PossessionManager"
@onready var dash_manager: DashManager = $"../DashManager"
@onready var morph_skill: Node2D = $MorphSkill
signal stolen_skill_used # signal untuk kasih shield
var homing_shot_ready : bool = false
var triple_homing_shot_ready : bool = false
var wolf_morph_ready : bool = false
var slash_shot_ready : bool = false # <-- TAMBAHAN

func start_or_return_super_dash() :
	super_dash.start_super_dash()

func use_morph_skill() -> void:
	if morph_skill.start_skill(homing_shot_ready, triple_homing_shot_ready, wolf_morph_ready, slash_shot_ready) :
		homing_shot_ready = false
		triple_homing_shot_ready = false
		wolf_morph_ready = false
		slash_shot_ready = false
		emit_signal("stolen_skill_used")

func use_pin() -> void:
	pin.throw_pin()

func is_possesing() -> bool :
	return possession_manager.is_possessing

func is_dashing() -> bool :
	return dash_manager.is_dashing

func is_casting_skill() -> bool :
	# 'morph_skill.is_active()' sudah mencakup semua skill dash, jadi tidak perlu diubah
	return super_dash.is_active() or pin.is_active() or morph_skill.is_active()

func add_pin() :
	pin.add_count()

func morph(name:String) :
	if name.begins_with("ShootingEnemy") :
		homing_shot_ready = true
	elif name.begins_with("DashShootingEnemy") :
		triple_homing_shot_ready = true
	elif name.begins_with("Wolf") :
		wolf_morph_ready = true
	elif name.begins_with("BrokenPuppet"):
		slash_shot_ready = true
