class_name GameAProjectile
extends Area2D

var direction : Vector2 = Vector2.ZERO
var speed : float = 250.0
var damage : float = 1.9

@export var life_time = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	rotation = direction.angle()
	
func _physics_process(delta: float) -> void:
	# check if the timer stoped
	life_time-=delta
	if life_time<=0.0:
		queue_free()
		return
	global_position += direction * speed* delta

func _on_area_entered(area : Area2D):
	if area.get_parent() == null: return
	var player := area.get_parent()
	if player is CharacterBody2D:
		player.take_damage(damage)
	queue_free()

func _on_body_entered(body : Node2D):
	queue_free()
