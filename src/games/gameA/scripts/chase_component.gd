class_name ChaseComponent
extends Node

signal started_chasing
signal lost_player

@export var speed: float = 100
@export_flags_2d_physics var wall_mask: int = 4
@export var detection_area: Area2D

@onready var enemy : Enemy = get_parent()

var is_chasing := false
var trail: BreadcrumbTrail


func _ready() -> void:
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	trail = get_tree().get_first_node_in_group("breadcrumb_trail")

func update(_delta: float) -> void:
	var player := get_player()
	if player == null:
		stop()
		return

	if not is_chasing:
		if detection_area.overlaps_body(player) and can_see_player():
			is_chasing = true
			started_chasing.emit()
		else:
			stop()
			return

	var target = _get_target()
	if target == null:
		is_chasing = false
		stop()
		lost_player.emit()
	else:
		_move_towards(target)
	_update_vision()



func get_player() -> CharacterBody2D:
	return trail.player


func can_see_player() -> bool:
	var player := get_player()
	return player != null and _can_reach(player.global_position)


func distance_to_player() -> float:
	var player := get_player()
	return enemy.global_position.distance_to(player.global_position) if player else INF


func _get_target() -> Variant:
	if can_see_player():
		return get_player().global_position
	var crumb = trail.get_newest_valid_crumb(
		enemy.global_position, _space(), wall_mask, [enemy.get_rid()])
	if not crumb:
		return null
	return crumb.position
	

## TODO
func _update_vision() -> void:
	pass
		
func _move_towards(target: Vector2) -> void:
	enemy.velocity = enemy.global_position.direction_to(target) * speed

func _can_reach(target: Vector2) -> bool:
	return trail.is_crumb_valid(
		enemy.global_position, target, _space(), wall_mask, [enemy.get_rid()])

func stop():
	enemy.velocity = Vector2.ZERO

func _space() -> PhysicsDirectSpaceState2D:
	return enemy.get_world_2d().direct_space_state
