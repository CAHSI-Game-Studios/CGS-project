class_name BreadcrumbTrail
extends Node2D

class Crumb:
	var position: Vector2

	func _init(p_position: Vector2) -> void:
		position = p_position

@export var player: CharacterBody2D
@export var max_crumbs: int = 10
@export var min_distance: float = 16.0
@export var debug_draw: bool = true:
	set(value):
		debug_draw = value
		queue_redraw()

var crumbs: Array[Crumb] = []


func _ready() -> void:
	add_to_group("breadcrumb_trail")
	top_level = true
	global_position = Vector2.ZERO

	if player == null:
		player = get_parent() as CharacterBody2D
	if player == null:
		push_warning("BreadcrumbTrail: no player assigned and parent is not a CharacterBody2D.")


func _on_spawn_timeout() -> void:
	if player == null:
		return

	var pos := player.global_position
	if not crumbs.is_empty() and crumbs.back().position.distance_to(pos) < min_distance:
		return

	crumbs.append(Crumb.new(pos))
	if crumbs.size() > max_crumbs:
		crumbs.pop_front()
	queue_redraw()


func clear_trail() -> void:
	crumbs.clear()
	queue_redraw()


func is_crumb_valid(from: Vector2, to: Vector2, space: PhysicsDirectSpaceState2D,
		wall_mask: int, exclude: Array[RID] = []) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, wall_mask, exclude)
	return space.intersect_ray(query).is_empty()


func get_newest_valid_crumb(from: Vector2, space: PhysicsDirectSpaceState2D,
		wall_mask: int, exclude: Array[RID] = []) -> Crumb:
	for i in range(crumbs.size() - 1, -1, -1):  # newest to oldest
		if is_crumb_valid(from, crumbs[i].position, space, wall_mask, exclude):
			return crumbs[i]
	return null

## ------------- Debug -----------------
func _draw() -> void:
	if not debug_draw or crumbs.is_empty():
		return
	var count := crumbs.size()
	for i in count:
		var alpha := 0.3 + 0.7 * float(i) / maxi(count - 1, 1)
		var color := Color(1, 0.5, 0, alpha)
		if i > 0:
			draw_line(crumbs[i - 1].position, crumbs[i].position, color, 1.0)
		draw_circle(crumbs[i].position, 3.0, color)
