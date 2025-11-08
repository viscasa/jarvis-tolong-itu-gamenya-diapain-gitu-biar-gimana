extends Line2D

var possession_manager: PossessionManager

var max_connected: int = 3
var list_target: Array = []
var can_cast: bool = true

func _physics_process(delta: float) -> void:
	for i in list_target.size() :
		if !get_point_position(i) :
			return
		if !list_target[i]:
			return
		set_point_position(i, list_target[i].get_global_position())

func _ready() -> void:
	var player = get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player:
		possession_manager = player.get_node("PossessionManager") as PossessionManager
	possession_manager.possessed.connect(_on_possessed)

func _on_possessed(target) -> void :
	if !can_cast:
		return
	list_target.append(target)
	print(list_target, target.get_global_position())
	self.add_point(target.get_global_position())
	if list_target.size()>max_connected:
		can_cast = false
		if list_target[0] == list_target[max_connected] :
			pass ##TODO
		await get_tree().create_timer(1).timeout
		list_target = []
		self.clear_points()
		can_cast = true
		
