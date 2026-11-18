class_name GameAEnemy
extends GameACharacter

@onready var hitbox: Area2D = $Hitbox
@export var player: CharacterBody2D
@export var dmg : int = 20


func _ready() -> void:
	super()
	add_to_group("enemies")

func can_act() -> bool:
	return player != null

## the childs will override this function
func update_behavior(_delta: float) -> void:
	# chase player
	chase_target(player)

## ------- CHASE BEHAVIOR ----------------
func chase_target(target : Node2D) -> void:
	if can_chase:
		move_towards_point(target.global_position, SPEED)

func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)
