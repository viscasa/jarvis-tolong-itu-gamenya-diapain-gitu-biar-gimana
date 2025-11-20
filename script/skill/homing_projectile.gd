extends CharacterBody2D
class_name HomingProjectile

@export var speed: float = 300.0
@export var turn_rate: float = 10.0
@export var damage: float = 15.0
@export var lifetime: float = 3.0

@export var proximity_threshold: float = 20.0

@onready var timer: Timer = $Timer

var target: Node2D = null
var current_direction: Vector2 = Vector2.RIGHT
var chain_count: int = 0
var bodies_hit: Array = [] 
func _ready() -> void:
	add_to_group("player_projectiles")
	timer.wait_time = lifetime
	timer.timeout.connect(queue_free)
	timer.start()

func launch(_initial_direction: Vector2):
	target = _find_nearest_enemy()
	current_direction = _initial_direction.normalized()
	velocity = current_direction * speed
	rotation = current_direction.angle()

func _physics_process(delta: float) -> void:
	
	if is_instance_valid(target) and !target.current_state==3:
		var direction_to_target = (target.global_position - global_position).normalized()
		var distance_sq_to_target = global_position.distance_squared_to(target.global_position)
		
		if distance_sq_to_target < proximity_threshold * proximity_threshold:
			current_direction = direction_to_target
		else:
			current_direction = current_direction.lerp(direction_to_target, turn_rate * delta).normalized()
	else:
		if get_tree().get_nodes_in_group("enemies").size() == 0:
			target = null 
		else :
			target = _find_nearest_enemy()
	
	velocity = current_direction * speed
	rotation = velocity.angle()
	
	move_and_slide()

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body and body.is_in_group("player"):
		return
	
	if body in bodies_hit:
		return
		
	var enemy_stats : Stats
	if body is CharacterBody2D :
		enemy_stats = body.get_node("Stats")
	else :
		enemy_stats= body.get_owner().get_node("Stats")
	if !enemy_stats :
		return
		
	var hit_direction = (body.global_position - global_position).normalized()
	enemy_stats.take_damage(damage, hit_direction)
	bodies_hit.append(body) 
	if chain_count > 0:
		chain_count -= 1
		target = _find_nearest_enemy(bodies_hit) 
		if not is_instance_valid(target):
			queue_free()
		return 



	queue_free()

func _find_nearest_enemy(exclude_list: Array = []) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies") 
	var closest_enemy: Node2D = null
	var min_dist_sq: float = INF
	
	for enemy in enemies:
		if (not is_instance_valid(enemy)) or (enemy in exclude_list):
			continue
			
		var dist_sq = enemy.global_position.distance_squared_to(self.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_enemy = enemy
			
	return closest_enemy
