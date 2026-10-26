class_name Enemy_A
extends CharacterBody2D

@onready var chase: ChaseComponent = $ChaseComponent

func _ready() -> void:
	pass	
func _physics_process(delta: float) -> void:
	chase.update(delta)
	move_and_slide()
