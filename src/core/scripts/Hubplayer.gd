extends CharacterBody2D

@export var speed: float = 250.0
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down",
	)
	
	velocity = input_direction * speed
	move_and_slide()
	if input_direction == Vector2.ZERO:
		animated_sprite.play("default")
	elif abs(input_direction.x) > abs(input_direction.y):
		if input_direction.x > 0:
			animated_sprite.play("move_right")
		else:
			animated_sprite.play("move_left")
	else:
		if input_direction.y > 0:
			animated_sprite.play("move_down")
		else:
			animated_sprite.play("move_up")
