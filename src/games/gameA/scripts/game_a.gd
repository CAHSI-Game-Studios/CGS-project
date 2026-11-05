extends ArcadeGame

var _game_scene: PackedScene
var _running: bool = false
var _finished: bool = false
var _restarting: bool = false


#func _ready() -> void:
	# Load at runtime: preloading this scene from its own script is cyclic.
#	_game_scene = load(scene_file_path) as PackedScene
#	_stop_gameplay()
func _ready() -> void:
	_game_scene = load(scene_file_path) as PackedScene
	_stop_gameplay()
	_start_if_standalone.call_deferred()


func _start_if_standalone() -> void:
	if get_tree().current_scene == self:
		enter()
		

func _physics_process(_delta: float) -> void:
	if not _running or _finished or _restarting:
		return


func enter(_enterData: Variant = null) -> void:
	if _finished:
		return
	_running = true
	process_mode = Node.PROCESS_MODE_INHERIT


func exit() -> void:
	_finished = true
	_stop_gameplay()


func win() -> void:
	if not _running or _finished or _restarting:
		return
	# Guard first: an exit listener may synchronously call exit().
	_finished = true
	_stop_gameplay()
	request_exit()


func lose() -> void:
	restart()


func restart() -> void:
	if not _running or _finished or _restarting:
		return
	_restarting = true
	_stop_gameplay()
	# Loss may originate in a physics callback; replace nodes after it finishes.
	_restart_gameplay.call_deferred()


func _restart_gameplay() -> void:
	if _finished or is_queued_for_deletion():
		return
	# Recreate this scene's children while retaining the ArcadeGame instance
	# owned by GameManager. The Hub and the rest of the tree stay untouched.
	var fresh_game := _game_scene.instantiate()
	# The temporary root is being discarded, so release its scene ownership.
	for descendant in fresh_game.find_children("*", "", true, false):
		if descendant.owner == fresh_game:
			descendant.owner = null
	for child in get_children():
		remove_child(child)
		child.queue_free()
	for child in fresh_game.get_children():
		fresh_game.remove_child(child)
		add_child(child)
	fresh_game.free()
	_restarting = false
	_running = true
	process_mode = Node.PROCESS_MODE_INHERIT


func _stop_gameplay() -> void:
	_running = false
	process_mode = Node.PROCESS_MODE_DISABLED
	var player: CharacterBody2D = get_node_or_null('player')
	if not player: return 
	player.velocity = Vector2.ZERO


func _unhandled_key_input(event: InputEvent) -> void:
	if not _running or _finished or _restarting:
		return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	# Temporary debug controls, scoped to the active Game A instance.
	match event.keycode:
		KEY_1:
			get_viewport().set_input_as_handled()
			win()
		KEY_2:
			get_viewport().set_input_as_handled()
			restart()
