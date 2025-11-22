extends Marker2D
class_name EnemySpawner
@export_enum("Broken Puppet", "Wolf", "Shooting Enemy", "Dash Shooting Enemy") var ENEMY_TYPE:int = -1
var enemy_path = {
	0 : "res://scene/hostile/broken_puppet.tscn",
	1 : "res://scene/hostile/wolf.tscn",
	2 : "res://scene/hostile/shooting_enemy.tscn",
	3 : "res://scene/hostile/dash_shooting_enemy.tscn"
}

func spawn_enemy():
	if ENEMY_TYPE == -1 :
		ENEMY_TYPE = randi_range(0,3)
	var enemy_scene = load(enemy_path[ENEMY_TYPE])
	var enemy_instance = enemy_scene.instantiate()
	return enemy_instance
