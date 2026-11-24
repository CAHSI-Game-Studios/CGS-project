extends CharacterBody2D

@export var speed: float = 250.0
@export var can_move: bool = true
@export var only_horizontal: bool = false

func _physics_process(_delta: float) -> void:
	if not can_move:
		velocity = Vector2.ZERO
		$AnimatedSprite2D.stop()
		move_and_slide()
		return
		
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)
	
	if only_horizontal:
		input_direction.y = 0.0
		
	velocity = input_direction * speed
	
	
	if input_direction == Vector2.ZERO:
		$AnimatedSprite2D.stop()
		
	elif abs(input_direction.x) >= abs(input_direction.y):
		if input_direction.x >= 0:
			$AnimatedSprite2D.play("move_right")
		else:
			$AnimatedSprite2D.play("move_left")
			
	else:
		if input_direction.y >= 0:
			$AnimatedSprite2D.play("move_down")
		else:
			$AnimatedSprite2D.play("move_up")
	
	move_and_slide()
