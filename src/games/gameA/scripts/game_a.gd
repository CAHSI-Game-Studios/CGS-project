extends ArcadeGame

const PauseMenu := preload("res://core/scenes/pause_menu.gd")

@export_group("Dialogue")
@export var opening_dialogue: Dialogue
@export var before_fight_dialogue: Dialogue
@export var after_fight_dialogue: Dialogue
@export var boss_fight_dialogue: Dialogue
@export var ending_dialogue: Dialogue

var _game_scene: PackedScene
var _running: bool = false
var _finished: bool = false
var _restarting: bool = false
var _pause_menu: PauseMenu


#func _ready() -> void:
	# Load at runtime: preloading this scene from its own script is cyclic.
#	_game_scene = load(scene_file_path) as PackedScene
#	_stop_gameplay()
func _ready() -> void:
	_game_scene = load(scene_file_path) as PackedScene
	_connect_pause_controls()
	_stop_gameplay()
	_start_if_standalone.call_deferred()


func _connect_pause_controls() -> void:
	_pause_menu = get_node_or_null("PauseMenu") as PauseMenu
	if _pause_menu:
		$DialogueLayer/PauseButton.pressed.connect(GameA_pause)
		_pause_menu.exit_requested.connect(_on_pause_exit)
		_pause_menu.set_process(_running)


func GameA_pause() -> void:
	if _running and not _finished and not _restarting and _pause_menu and not get_tree().paused:
		_pause_menu.pause_game()


func _on_pause_exit() -> void:
	if get_tree().current_scene == self:
		exit()
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		request_exit()


func _start_if_standalone() -> void:
	if get_tree().current_scene == self:
		enter()
		

func _physics_process(_delta: float) -> void:
	if not _running or _finished or _restarting:
		return


func enter(_enterData: Variant = null) -> void:
	if _finished:
		return
	_resume_gameplay()
	play_dialogue(opening_dialogue)


func play_dialogue(dialogue: Dialogue) -> void:
	if not _running or dialogue == null:
		return
	_stop_gameplay()
	await _show_dialogue(dialogue)
	if not _finished:
		_resume_gameplay()


func _show_dialogue(dialogue: Dialogue) -> void:
	var system := get_node_or_null("DialogueLayer/DialogueSystem") as DialogueSystem
	if not system:
		return
	system.set_current_dialogue(dialogue)
	system.open_system()
	await system.visibility_changed


func exit() -> void:
	_finished = true
	_stop_gameplay()
	if _pause_menu and _pause_menu.is_open():
		_pause_menu.resume_game()


func win() -> void:
	if not _running or _finished or _restarting:
		return
	# Guard first: an exit listener may synchronously call exit().
	_finished = true
	_stop_gameplay()
	if ending_dialogue:
		await _show_dialogue(ending_dialogue)
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
	_connect_pause_controls()
	_restarting = false
	_resume_gameplay()


func _resume_gameplay() -> void:
	_running = true
	process_mode = Node.PROCESS_MODE_INHERIT
	if _pause_menu:
		_pause_menu.set_process(true)
		$DialogueLayer/PauseButton.disabled = false


func _stop_gameplay() -> void:
	_running = false
	process_mode = Node.PROCESS_MODE_DISABLED
	if _pause_menu:
		_pause_menu.set_process(false)
		$DialogueLayer/PauseButton.disabled = true
	var player: CharacterBody2D = get_node_or_null("Player")
	if player:
		player.velocity = Vector2.ZERO


func _unhandled_key_input(event: InputEvent) -> void:
	if not _running or _finished or _restarting:
		return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	# Temporary debug controls, scoped to the active Game A instance.
	var dialogue: Dialogue
	match event.keycode:
		KEY_1:
			get_viewport().set_input_as_handled()
			win()
		KEY_2:
			get_viewport().set_input_as_handled()
			restart()
		KEY_3:
			dialogue = before_fight_dialogue
		KEY_4:
			dialogue = after_fight_dialogue
		KEY_5:
			dialogue = boss_fight_dialogue
	if dialogue:
		get_viewport().set_input_as_handled()
		play_dialogue(dialogue)


func _on_death_zones_body_entered(body: Node2D) -> void:
	if body is GameAPlayer:
		body.take_damage(body.health)


func _on_life_zones_body_entered(body: Node2D) -> void:
	if body is GameAPlayer:
		var player := body as GameAPlayer
		player.heal(player.max_health)
