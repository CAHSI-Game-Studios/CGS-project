class_name GameAEnemy
extends CharacterBody2D

@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@onready var hitbox: Area2D = $Hitbox
@export var player: CharacterBody2D
@export var SPEED: float = 50
@export var health : int = 100
@export var dmg : int = 20
@onready var health_bar: ProgressBar = $UI/HealthBar

var can_chase: bool = true

func _ready() -> void:
	health_bar.value = health

func _physics_process(delta: float) -> void:
	if player == null:
		return
	update_behavior(delta)

## the childs will override this function
func update_behavior(_delta: float) -> void:
	chase_target(player)
	

func take_damage(amount):
	if amount >= health:
		health = 0
		# the enemy is dead
		queue_free()
	else:
		health -= amount
	health_bar.value = health

## ------- Chase Behavior ----------------
func chase_target(target: Node2D) -> void:
	if can_chase:
		chase(target)

func chase(target: Node2D) -> void:
	navigation.target_position = target.global_position
	var new_velocity := Vector2.ZERO
	if not navigation.is_navigation_finished():
		var next_path_pos := navigation.get_next_path_position()
		new_velocity = global_position.direction_to(next_path_pos) * SPEED

	if navigation.avoidance_enabled:
		navigation.velocity = new_velocity
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)

func has_line_of_sight(target: Node2D) -> bool:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(
		global_position, target.global_position, 4, [get_rid()]
	)
	
	return space.intersect_ray(query).is_empty()
func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	if not can_chase:
		return
	velocity = safe_velocity
	move_and_slide()

func stop_moving() -> void:
	velocity = Vector2.ZERO
	move_and_slide()

func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)
