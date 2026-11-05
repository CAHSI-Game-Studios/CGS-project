class_name GameAProjectileEnemy
extends GameAEnemy

enum State { CHASE, WINDUP, COOLDOWN }

@export var projectile_scene: PackedScene

@export var attack_distance : float = 120.0
@export var windup_time : float = 0.8
@export var projectile_speed : float = 250.0
@export var cooldown_time : float = 1.0


var state : State = State.CHASE
var state_timer : float = 0.0


func update_behavior(delta: float) -> void:
	match state:
		State.CHASE:
			if distance_to_player() <= attack_distance and has_line_of_sight(player):
				start_windup()
			else:
				super(delta)
		
		State.WINDUP:
			stop_moving()
			state_timer -= delta
			if state_timer <= 0.0:
				shoot()
				start_cooldown()
		State.COOLDOWN:
			stop_moving()
			state_timer-= delta
			if state_timer<=0.0:
				can_chase = true
				state = State.CHASE

func start_windup():
	state = State.WINDUP
	state_timer = windup_time
	can_chase = false

func shoot():
	var projectile: GameAProjectile = projectile_scene.instantiate()
	set_up_projectile(projectile)
	## add the projectile scene to the ACTUALLY game, not this enemy
	get_tree().current_scene.add_child(projectile)
	## projectile position its the enemy position
	projectile.global_position = global_position

func start_cooldown():
	state = State.COOLDOWN
	state_timer = cooldown_time

func set_up_projectile(projectile : GameAProjectile)->void:
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.speed = projectile_speed
	projectile.damage = dmg
	
	
	
