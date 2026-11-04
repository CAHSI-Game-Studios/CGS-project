extends ArcadeGame

const SPEED = 300.0

func _ready() -> void:
	pass
## Called every physics frame. _delta is the seconds between each frame. 
func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left","move_right","move_up","move_down")
	$Shrine/player.velocity = direction*SPEED
	$Shrine/player.move_and_slide()

## Called by the external system to start the game.
func enter( _enterData : Variant = null) -> void:
	pass
## Called by the external system before unloading. Each game is responsible for defining their exit function.
func exit() -> void:
	pass
