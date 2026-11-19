extends CanvasLayer

signal exit_requested


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()


func is_open() -> bool:
	return $Panel.is_visible_in_tree()


func toggle_pause() -> void:
	if not is_open():
		# Another screen may already own the paused state.
		if get_tree().paused:
			return
		pause_game()
	else:
		resume_game()


func pause_game() -> void:
	$Panel.show()
	get_tree().paused = true


func resume_game() -> void:
	$Panel.hide()
	get_tree().paused = false


func _on_resume_button_pressed() -> void:
	if is_open() and get_tree().paused:
		resume_game()


func _on_exit_button_pressed() -> void:
	if is_open() and get_tree().paused:
		resume_game()
		exit_requested.emit()
