extends Node2D

@onready var player: CharacterBody2D = null
@onready var health_manager: HealthManager = $"../HealthManager"
var possession_manager: PossessionManager
var dash_manager: DashManager
var attack_manager: AttackManager
signal exit_missed
# --- TAMBAHKAN/UBAH REFERENSI INI ---
var super_dash: SuperDash
var player_health: HealthManager # Ganti nama dari 'player_stats'
# ----------------------------------

var possesion_target:Node = null
var crit_interval: Array = [0.63,0.76]

func _ready() -> void:
	if owner is Player:
		player=owner
	if player:
		possession_manager = player.get_node("PossessionManager") as PossessionManager
		dash_manager = player.get_node("DashManager") as DashManager
		attack_manager = player.get_node("AttackManager") as AttackManager
		
		# --- PERBAIKAN REFERENSI ---
		super_dash = player.get_node("SkillManager/SuperDash") as SuperDash
		player_health = player.get_node("HealthManager") as HealthManager # Ambil HealthManager
		# --------------------------

		possession_manager.possessed.connect(_on_possessed)
		dash_manager.exit_dash_manual_started.connect(_on_exit)
		dash_manager.auto_exit_dash_started.connect(_on_auto_exit)

func _on_possessed(target) -> void :
	possesion_target = target

func _on_exit() -> void:
	if !possesion_target:
		return
		
	var is_critical:bool = false
	var time:float = possesion_target.get_current_circle_time()
	var stats = PlayerBuffManager.current_stats # Ambil stat terbaru
	
	var enemy : Node
	if possesion_target is CharacterBody2D :
		enemy = possesion_target
	else :
		enemy= possesion_target.get_owner()
		
	if time>=crit_interval[0] and time <= crit_interval[1]  :
		is_critical = true
		health_manager.heal(health_manager.heal_amount)
		player.morph(enemy.name)
		
		# --- [BOON "LUCKY FOOT"] ---
		if randf() < stats.perfect_possess_super_charge_chance:
			print("LUCKY FOOT!")
			super_dash.super_dash_recharge_counter = super_dash.super_dash_recharge_needed
			super_dash._process_recharge_counter() 
		# --------------------------
		
	else:
		# --- [BOON "HOUSE OF STRAW"] ---
		if stats.heal_on_miss > 0:
			print("HOUSE OF STRAW HEAL!")
			# Panggil fungsi 'heal' yang baru kita buat
			player_health.heal(stats.heal_on_miss)
			emit_signal("exit_missed")
		# ------------------------------------

	var player_dash_direction = dash_manager.exit_dash_direction
	var hit_direction = -player_dash_direction.normalized()
	
	var exit_damage = attack_manager.get_final_damage(is_critical)
	
	# (Logika 'House of Straw' -50% Dmg)
	# ...

	attack_manager.attack(possesion_target, hit_direction,  is_critical, exit_damage)
	
	possesion_target.exit()
	possesion_target = null

func _on_auto_exit() -> void:
	if !possesion_target:
		return
	possesion_target.auto_exit()
	possesion_target = null
