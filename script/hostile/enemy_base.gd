extends CharacterBody2D
class_name EnemyBase

@export var move_speed: float = 80.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5 

@onready var stats: Stats = $Stats
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Hitbox = $Hitbox
@onready var hitbox_shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var attack_timer: Timer = $AttackTimer

enum State { CHASE, ATTACK, POSSESSED, DEAD }
var current_state: State = State.CHASE 
var player_target: Node2D = null 

func _ready():
	hitbox_shape.disabled = true
	
	attack_timer.wait_time = attack_cooldown
	attack_timer.one_shot = true
	
	stats.no_health.connect(_on_death)
	
	var player_nodes = get_tree().get_root().find_children("*", "Player", true, false)
	
	if not player_nodes.is_empty():
		player_target = player_nodes[0]
	
	if not is_instance_valid(player_target):
		print("PERINGATAN: Enemy " + name + " tidak bisa menemukan 'player' di scene!")
		current_state = State.DEAD 
		set_physics_process(false)

func _physics_process(delta):
	if current_state == State.DEAD or current_state == State.POSSESSED:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if not is_instance_valid(player_target):
		velocity = Vector2.ZERO
		#animated_sprite.play("idle")
		move_and_slide()
		return

	match current_state:
		State.CHASE:
			_state_chase(delta) 
			var distance_to_player = global_position.distance_to(player_target.global_position)
			if distance_to_player <= attack_range and attack_timer.is_stopped():
				print("change to att")
				current_state = State.ATTACK
				_perform_attack()
				#animated_sprite.play("attack")
				attack_timer.start() 

		State.ATTACK:
			_state_attack(delta)
			
	move_and_slide()
	
func _state_chase(delta):
	if (global_position.distance_to(player_target.global_position) <= attack_range):
		return
	var direction = global_position.direction_to(player_target.global_position)
	velocity = direction * move_speed
	#animated_sprite.play("walk")
	animated_sprite.flip_h = (velocity.x > 0)

func _state_attack(delta):
	velocity = Vector2.ZERO
	
func connect_signals():
	stats.no_health.connect(_on_death)
	
func on_possessed():
	current_state = State.POSSESSED
	velocity = Vector2.ZERO

func on_released():
	current_state = State.CHASE 


func _perform_attack():
	hitbox.damage = stats.get_final_damage()
	
	hitbox_shape.disabled = false
	
	await get_tree().create_timer(0.2).timeout
	
	if self and hitbox_shape:
		hitbox_shape.disabled = true
		
	current_state = State.CHASE

func _on_death():
	print(name + " mati!")
	current_state = State.DEAD
	
	set_physics_process(false)
	$CollisionShape2D.disabled = true
	if $Hurtbox: 
		$Hurtbox/CollisionShape2D.disabled = true
	
	#animated_sprite.play("death") 
	
	await animated_sprite.animation_finished
	queue_free()
