class_name GameAProjectile
extends Area2D

var direction : Vector2 = Vector2.ZERO
var speed : float = 250.0
var damage : float = 1.9

@export var life_time = 3.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	rotation = direction.angle()
	
func _physics_process(delta: float) -> void:
	## check if the timer stoped
	life_time-=delta
	if life_time<=0.0:
		queue_free()
		return
	global_position += direction * speed* delta

func _on_body_entered(body : Node2D):
	## for now
	if body is CharacterBody2D:
		pass ##<- this should be a take damage func of the player
	queue_free()
