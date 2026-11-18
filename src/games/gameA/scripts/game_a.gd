extends ArcadeGame

const RESULT_SCENE := preload("res://games/gameA/scenes/game_a_result.tscn")
const PREVIEW_COIN_TOTAL := 2

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
var _result: GameAResult


func _ready() -> void:
	# Preloading this scene from its own script would create a dependency cycle.
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
	_close_result_preview()


func win() -> void:
	if not _running or _finished or _restarting:
		return
	_finished = true
	_stop_gameplay()
	if ending_dialogue:
		await _show_dialogue(ending_dialogue)
	request_exit()


func lose() -> void:
	restart()


func _show_result_preview(won: bool) -> void:
	get_tree().paused = true
	_result = RESULT_SCENE.instantiate() as GameAResult
	_result.retry_requested.connect(_retry_result_preview)
	_result.exit_requested.connect(_return_to_hub)
	add_child(_result)
	_result.show_result(won, PREVIEW_COIN_TOTAL)


func _close_result_preview() -> void:
	if not _result:
		return
	_result.hide()
	_result.queue_free()
	_result = null
	get_tree().paused = false


func _retry_result_preview() -> void:
	_close_result_preview()
	restart()


func _return_to_hub() -> void:
	if not _result or _restarting:
		return
	if get_tree().current_scene == self:
		exit()
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		request_exit()


func restart() -> void:
	if not _running or _finished or _restarting:
		return
	_restarting = true
	_stop_gameplay()
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
	_resume_gameplay()


func _resume_gameplay() -> void:
	_running = true
	process_mode = Node.PROCESS_MODE_INHERIT


func _stop_gameplay() -> void:
	_running = false
	process_mode = Node.PROCESS_MODE_DISABLED
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
		KEY_7, KEY_8:
			get_viewport().set_input_as_handled()
			_show_result_preview(event.keycode == KEY_7)
	if dialogue:
		get_viewport().set_input_as_handled()
		play_dialogue(dialogue)
