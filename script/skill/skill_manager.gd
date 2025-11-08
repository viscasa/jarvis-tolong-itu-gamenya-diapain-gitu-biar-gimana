extends Node2D
class_name SkillManager

@onready var super_dash: SuperDash = $SuperDash

func start_or_return_super_dash() :
	super_dash.start_super_dash()
