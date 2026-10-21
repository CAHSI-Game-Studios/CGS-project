extends Node
class_name Main

@export var terminal: DebugTerminal
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	#if Input.is_action_just_pressed("open_terminal"):
		#terminal.visible = !terminal.visible
		pass
#func _input(event: InputEvent) -> void:
	#if event.is_action("debug") and not event.is_echo():
		#terminal.visible = !terminal.visible
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_terminal") and not event.is_echo():
		terminal.visible = !terminal.visible
