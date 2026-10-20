class_name GameManager extends Node
## A class responisble for loading, unloading and containing [ArcadeGame]s. 
##
## This node will at most contain a single [ArcadeGame] child node. [br]
## It propogates enter data to the entered game


## Emitted after a game has successfully entered.
signal game_started(enterData : Variant)
## Emitted after a game has completed its exit lifecycle.
signal game_exited(exitData : Variant)
## A reference to the [ArcadeGame] child node.
var currentGame : ArcadeGame

## Starts an [ArcadeGame] from an already existing instance.[br]
## Parameter [param gameToLoad] is a reference to an existing [ArcadeGame] node. [br]
## Parameter [param enterData] is currently unused, but can contain information that may be used in [method ArcadeGame.enter]. [br]
## Returs true if the game is loaded, false otherwise.[br]
## Calls [method ArcadeGame.enter], emits [signal game_started].
func start_game_from_scene( gameToLoad : ArcadeGame, enterData : Variant = null ) -> bool:
	if is_game_running():
		push_error("Attempting to add a new game while another is currently running.")
		return false
	currentGame = gameToLoad
	currentGame.exit_requested.connect(_on_game_exit_requested)
	if currentGame.get_parent() != null:
		push_warning("Game to add already has parent: %s. Reparenting." % currentGame.get_parent().name)
		currentGame.reparent(self)
	else:
		add_child(currentGame)
	await currentGame.ready
	currentGame.enter(enterData)
	game_started.emit(enterData)
	return true

## Starts an [ArcadeGame] from a [PackedScene]. [br]
## [param sceneToLoad] is a [Resource] loaded elsewhere.
## Returns true and starts an [ArcadeGame] if the instantiated [PackedScene] is an [ArcadeGame], [br]
## fails and returns false otherwise.
## Calls [method start_game_from_scene] from the instantiated [ArcadeGame].
func start_game_from_packed_scene( sceneToLoad : PackedScene, enterData : Variant = null) -> bool:
	var gameScene := sceneToLoad.instantiate()
	if gameScene is not ArcadeGame:
		push_error("Invalid packed scene. Expected: ArcadeGame, Recieved: %s" % gameScene.get_class())
		return false
	return await start_game_from_scene(gameScene, enterData)

func start_game_from_path( scenePath : String, enterData : Variant = null) -> bool:
	if not FileAccess.file_exists(scenePath):
		push_error("%s not found." % scenePath)
		return false
	var packedScene := load(scenePath)
	if packedScene is PackedScene:
		return await start_game_from_packed_scene(packedScene, enterData)
	else:	
		push_error("Expected: PackedScene, Recieved: %s", packedScene.get_class())
		return false


func exit_game(exitData : Variant = null) -> bool:
	if not is_game_running():
		return false
	var game := currentGame
	await game.exit()
	game.queue_free()
	await game.tree_exited
	currentGame = null
	game_exited.emit(exitData)
	return true

func is_game_running() -> bool:
	return currentGame != null

func _on_game_exit_requested(exitData : Variant) -> void:
	# There might be a case where a game requests to exit, but is unable/not allowed to for some reason.
	# It is inside this function that a condition for exit for a game can be set. For now though, we will always exit upon request.
	exit_game(exitData)
 
