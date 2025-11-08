extends Node2D

@onready var player: CharacterBody2D = null
var possession_manager: PossessionManager
var dash_manager: DashManager
var attack_manager: AttackManager

var possesion_target:Node = null

func _ready() -> void:
	if owner is Player:
		player=owner
	if player:
		possession_manager = player.get_node("PossessionManager") as PossessionManager
		dash_manager = player.get_node("DashManager") as DashManager
		attack_manager = player.get_node("AttackManager") as AttackManager
		possession_manager.possessed.connect(_on_possessed)
		dash_manager.exit_dash_manual_started.connect(_on_exit)
		dash_manager.auto_exit_dash_started.connect(_on_auto_exit)

func _on_possessed(target) -> void :
	possesion_target = target

func _on_exit() -> void:
	if !possesion_target:
		return

	attack_manager.attack(possesion_target, possesion_target.get_current_circle_time())
	possesion_target.exit()
	
	possesion_target = null

func _on_auto_exit() -> void:
	if !possesion_target:
		return
	print("hello")
	possesion_target.auto_exit()

	possesion_target = null
