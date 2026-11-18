class_name GameAShockwave
extends Area2D

@export var max_radius: float = 140.0
@export var duration: float = 0.5
@export var ring_thickness: float = 16.0
@export var color: Color = Color(0.6, 0.2, 1.0)

# the enemy will overwrite this 
var damage: int = -1

var radius: float = 0.0
var has_hit: bool = false

@onready var collision: CollisionShape2D = $CollisionShape2D
var shape: CircleShape2D


func _ready() -> void:
	# copy of the circule shape
	shape = collision.shape.duplicate()
	collision.shape = shape
	set_radius(0.0)

	area_entered.connect(_on_area_entered)
	
	# increase the radius little by little with the duration variable
	var tween := create_tween()
	tween.tween_method(set_radius, 0.0, max_radius, duration)
	tween.tween_callback(queue_free)


func set_radius(value: float) -> void:
	radius = value
	# dummy case
	shape.radius = max(value, 0.1)
	
	# draw the shape if the radius changes
	queue_redraw()  


func _draw() -> void:
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, color, ring_thickness)

func _on_area_entered(area: Area2D) -> void:
	if has_hit:
		return
	var target := area.get_parent()
	if target == null or target is not CharacterBody2D:
		return

	# it will only damage the player if they are at the edges.
	var distance := global_position.distance_to(target.global_position)
	if distance < radius - ring_thickness:
		return

	has_hit = true
	target.take_damage(damage)
	
