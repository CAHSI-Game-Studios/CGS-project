class_name GameAEnemy
extends CharacterBody2D

@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@export var player: CharacterBody2D
@export var SPEED: float = 20.0

@export var attack_distance : float = 10.0

var can_chase = true

func _physics_process(_delta: float) -> void:
	chase_target(player)

func behavior(target):
	if player == null:
		return

	navigation.target_position = target.global_position

	var new_velocity := Vector2.ZERO
	if not navigation.is_navigation_finished():
		var next_path_pos := navigation.get_next_path_position()
		new_velocity = global_position.direction_to(next_path_pos) * SPEED

	if navigation.avoidance_enabled:
		navigation.velocity = new_velocity
	else:
		_on_navigation_agent_2d_velocity_computed(new_velocity)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = safe_velocity
	move_and_slide()

func chase_target(target):
	if can_chase:
		behavior(target)
