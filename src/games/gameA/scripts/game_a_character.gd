class_name GameACharacter
extends CharacterBody2D

@onready var navigation: NavigationAgent2D = $NavigationAgent2D
@export var SPEED: float = 50
@export var health : int = 100
var health_bar: ProgressBar

var can_chase: bool = true

## ------- KNOCKBACK ----------------
@export var knockback_light_speed: float = 200.0
@export var knockback_heavy_speed: float = 400.0
@export var knockback_friction: float = 800.0

var knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	health_bar = get_health_bar()
	if health_bar:
		health_bar.max_value = health
		health_bar.value = health

# This is to ensure the code works for child objects that are bosses, 
# bosses have a canvas layer for the HealthBar, while regular enemies do not.
func get_health_bar() -> ProgressBar:
	return get_node_or_null("UI/HealthBar")

func _physics_process(delta: float) -> void:
	if is_knocked_back():
		update_knockback(delta)
		return

	if not can_act():
		return
	update_behavior(delta)

func can_act() -> bool:
	return true

## the childs will override this function
func update_behavior(_delta: float) -> void:
	pass

## ------- DAMAGE ----------------
func take_damage(amount: int, direction: Vector2 = Vector2.ZERO, heavy: bool = false) -> void:
	health = max(health - amount, 0)
	if health_bar:
		health_bar.value = health
	if health == 0:
		die()
		return

	apply_knockback(direction, heavy)

func die():
	queue_free()

## ------- KNOCKBACK ----------------
func apply_knockback(direction: Vector2, heavy: bool = false, multipier : float = 1.0) -> void:
	var speed := knockback_heavy_speed if heavy else knockback_light_speed
	knockback_velocity = direction.normalized() * speed * multipier

func update_knockback(delta: float) -> void:
	velocity = knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_friction * delta)

func is_knocked_back() -> bool:
	return knockback_velocity != Vector2.ZERO

## ------- MOVEMENT ----------------
func move_towards_point(point : Vector2, speed : float) -> void:
	navigation.target_position = point
	var new_velocity := Vector2.ZERO
	if not navigation.is_navigation_finished():
		var next_path_pos := navigation.get_next_path_position()
		new_velocity = global_position.direction_to(next_path_pos) * speed

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
	if not can_chase or is_knocked_back():
		return
	velocity = safe_velocity
	move_and_slide()

func stop_moving() -> void:
	velocity = Vector2.ZERO
	move_and_slide()
