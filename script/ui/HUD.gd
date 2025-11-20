extends CanvasLayer

@onready var cooldown_bar: ProgressBar = %DashCooldownBar
@onready var dash_label: Label = %DashLabel
@onready var weak_lock_bar: ProgressBar = %WeakLockBar
@onready var stats_label: Label = %StatsLabel

var player: CharacterBody2D
var dash: DashManager
var poss: PossessionManager

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		dash = player.get_node("DashManager") as DashManager
		poss = player.get_node("PossessionManager") as PossessionManager

func _process(_delta: float) -> void:
	if dash == null:
		return

	var cd: float = float(dash.cooldown_timer)
	var cd_total: float = float(dash.COOLDOWN)
	var ready: float = clamp(1.0 - (cd / max(cd_total, 0.0001)), 0.0, 1.0)
	cooldown_bar.value = ready
	dash_label.text = "Dash CD: %.2fs" % cd if cd > 0.0 else "Dash READY"

	var wt: float = float(dash.weak_exit_lock_timer)
	weak_lock_bar.visible = wt > 0.0
	if wt > 0.0:
		weak_lock_bar.value = clamp(1.0 - (wt / max(float(dash.WEAK_EXIT_LOCK_TIME), 0.0001)), 0.0, 1.0)

	var possessing: bool = poss != null and bool(poss.is_possessing)
	stats_label.text = "dashing: %s\nexit dashing: %s\nweak lock: %.2fs\npossessing: %s" % [
		str(dash.is_dashing),
		str(dash.is_exit_dashing),
		wt,
		str(possessing)
	]
