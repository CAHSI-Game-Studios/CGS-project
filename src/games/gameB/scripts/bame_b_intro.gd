extends Node2D


@export var line: Dialogue
# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	$DialogueSystem.open_system()
	$DialogueSystem.set_current_dialogue(line)
