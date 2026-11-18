extends Node2D
signal transition_sequence 
@export var starting_dialogue: Dialogue

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$DialogueSystem.open_system()
	$Player.can_move = false
	$Timer.start()
	$DialogueSystem.set_current_dialogue(starting_dialogue)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_area_2d_body_entered(body: Node2D) -> void:
	transition_sequence.emit()
	$Player.can_move = false


func _on_timer_timeout() -> void:
	$Player.can_move = true
	$DialogueSystem.close_system()
