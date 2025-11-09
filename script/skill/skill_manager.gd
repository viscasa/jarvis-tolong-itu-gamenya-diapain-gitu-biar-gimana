extends Node2D
class_name SkillManager

@onready var super_dash: SuperDash = $SuperDash
@onready var pin: Pin = $Pin
@onready var possession_manager: PossessionManager = $"../PossessionManager"
@onready var dash_manager: DashManager = $"../DashManager"

func _process(delta: float) -> void:
	pass
	#print("Possesing = %s, Dashing = %s, Casting =%s" % [is_possesing(),is_dashing(), is_casting_skill()])

func start_or_return_super_dash() :
	super_dash.start_super_dash()

func use_pin() -> void:
	pin.throw_pin()

func is_possesing() -> bool :
	return possession_manager.is_possessing

func is_dashing() -> bool :
	return dash_manager.is_dashing

func is_casting_skill() -> bool :
	return super_dash.is_active() or pin.is_active()

func morph(name:String) :
	if name.begins_with("Pin") :
		pin.add_count()
