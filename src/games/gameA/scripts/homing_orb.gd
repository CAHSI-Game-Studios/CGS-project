extends GameAProjectile

@export var turn_speed : float = 2.0
@export var homing_time : float = 3.0

# make sure to assing the player
var target : CharacterBody2D

var homing_timer : float = 0.0

func _ready() -> void:
	super()
	homing_timer = homing_time

func _physics_process(delta: float) -> void:
	if homing_timer > 0.0:
		homing_timer -= delta
		
		var new_direction := global_position.direction_to(target.global_position)
		var angle := direction.angle_to(new_direction)
		var max_turn := turn_speed * delta
		
		direction = direction.rotated(clamp(angle, -max_turn, max_turn))
		rotation = direction.angle()
	
	super(delta)
