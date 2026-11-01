extends ArcadeGame

# Connect currency/reward handling here when it is implemented.
signal game_won

const GAMEPLAY_SCENE = preload(
    "res://games/gameA/scenes/gameplay.tscn"
)

@onready var gameplay: Node = $Gameplay

var _run_ended := false


func win_game() -> void:
	if _run_ended:
		return

	# Register the win before doing anything else.
	_run_ended = true
	gameplay.process_mode = Node.PROCESS_MODE_DISABLED

	game_won.emit()
	print("Game A: won; requesting exit. Gameplay active: ", gameplay.can_process())
	request_exit()


func lose_game() -> void:
	if _run_ended:
		return

	_run_ended = true
	gameplay.process_mode = Node.PROCESS_MODE_DISABLED

	# Wait until collision/physics callbacks finish.
	_restart_gameplay.call_deferred()


func _restart_gameplay() -> void:
	remove_child(gameplay)
	gameplay.queue_free()

	gameplay = GAMEPLAY_SCENE.instantiate()
	gameplay.name = "Gameplay"
	add_child(gameplay)

	_run_ended = false
	print("Game A: restarted. Gameplay active: ", gameplay.can_process())


# Temporary testing controls. Real win/loss detectors call the same functions.
# Keep this on the Game A root so the keys still work when Gameplay is stopped.
func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return

	if event is InputEventKey:
		if not event.pressed or event.echo:
			return

		match event.keycode:
			KEY_1:
				win_game()
			KEY_2:
				lose_game()
