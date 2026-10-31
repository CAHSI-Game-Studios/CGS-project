extends ArcadeGame

@export var SPEED = 200.0

func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	var player = get_node_or_null("player")
	if player == null:
		return
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	player.velocity = direction * SPEED
	player.move_and_slide()

func enter( _enterData : Variant = null) -> void:
	pass
func exit() -> void:
	pass
