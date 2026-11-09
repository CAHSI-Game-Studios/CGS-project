extends Node2D


#determines how fast it will move
var velocity = 0

#Sends a signal to indicate that note has despawned
signal despawned

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= velocity*delta



func _on_note_area_area_entered(area: Area2D) -> void:
	despawned.emit()
	queue_free()
