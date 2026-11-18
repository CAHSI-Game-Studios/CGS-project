extends Node
class_name Main

@export var terminal: DebugTerminal
@export var game_a: PackedScene

@onready var hub: Control = $HubScene
@onready var game_manager: GameManager = $GameManager
@onready var play_game_a: Button = $HubScene/Menu/Center/Actions/PlayGameA


func _ready() -> void:
	play_game_a.pressed.connect(_on_play_game_a_pressed)
	game_manager.game_started.connect(_on_game_started)
	game_manager.game_exited.connect(_on_game_exited)
	play_game_a.grab_focus()


func _on_play_game_a_pressed() -> void:
	game_manager.start_game_from_packed_scene(game_a)


func _on_game_started(_enter_data: Variant) -> void:
	hub.hide()


func _on_game_exited(_exit_data: Variant) -> void:
	hub.show()
	play_game_a.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_terminal") and not event.is_echo():
		terminal.visible = !terminal.visible
