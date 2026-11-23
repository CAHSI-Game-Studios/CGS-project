extends Node2D


#determines how fast it will move
var velocity = 0
var type = "s,d,j,k"
#Sends a signal to indicate that note has despawned


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x += velocity*delta


func set_key_label(letter: String) -> void:
	type = letter.to_lower()
	if has_node("Label"):
		$Label.text = letter.to_upper()
	
