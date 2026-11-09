extends CanvasLayer
signal exit_requested

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause"):
		toggle_pause()

func toggle_pause() -> void:
	if not $Panel.is_visible_in_tree():
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
	if $Panel.is_visible_in_tree() and get_tree().paused == true:
		resume_game()

func _on_exit_button_pressed() -> void:
	if $Panel.is_visible_in_tree() and get_tree().paused == true:
		resume_game()
		exit_requested.emit()
