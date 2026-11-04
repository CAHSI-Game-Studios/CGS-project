extends Node
class_name Main

@export var terminal: DebugTerminal

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_terminal") and not event.is_echo():
		terminal.visible = !terminal.visible
