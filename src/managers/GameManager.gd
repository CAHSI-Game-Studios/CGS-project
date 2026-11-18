class_name GameManager
extends Node


## Manages the loading, execution, and unloading of [ArcadeGame] instances.
##
## [GameManager] acts as the lifecycle owner of arcade minigames. It may
## contain at most one active [ArcadeGame] at a time.
##
## The manager is responsible for: [br]
## - Adding an [ArcadeGame] to the scene tree. [br]
## - Forwarding entry data to [method ArcadeGame.enter]. [br]
## - Listening for [signal ArcadeGame.exit_requested]. [br]
## - Forwarding exit data to [method ArcadeGame.exit]. [br]
## - Removing the game from the scene tree. [br]
## - Reporting game lifecycle changes to external systems. [br]
## [br]
## Games may be started from: [br]
## - An existing [ArcadeGame] instance using [method start_game_from_scene]. [br]
## - A [PackedScene] using [method start_game_from_packed_scene]. [br]
## - A resource path using [method start_game_from_path]. [br]
## [br]
## [GameManager] does not contain game-specific behavior. Individual games
## communicate their desire to close through [signal ArcadeGame.exit_requested].


## Emitted after an [ArcadeGame] has successfully entered.
##
## [param enterData] contains the same data supplied when the game was started.
## The contents and interpretation of this value are game-specific.
signal game_started(enterData : Variant)


## Emitted after an [ArcadeGame] has completed its exit lifecycle and has been
## removed from the scene tree.
##
## [param exitData] contains data returned by the game or supplied to
## [method exit_game]. The contents and interpretation of this value are
## game-specific.
signal game_exited(exitData : Variant)


## Reference to the currently running [ArcadeGame].
##
## Contains [code]null[/code] when no game is running.
##
## This reference is assigned when a game begins its startup lifecycle and
## cleared once that game has left the scene tree.
var currentGame : ArcadeGame


## Starts an [ArcadeGame] from an already existing instance. [br]
## [br]
## [param gameToLoad] must reference an existing [ArcadeGame] instance. [br]
## [br]
## [param enterData] contains optional data that is forwarded to 
## [method ArcadeGame.enter]. Its structure is defined by the individual game. [br]
## [br]
## If [param gameToLoad] already belongs to another parent, it is reparented
## to this [GameManager]. Otherwise, it is added as a child normally. [br]
## [br]
## The manager connects to [signal ArcadeGame.exit_requested] before the game
## begins so that exit requests can be handled immediately. [br]
## [br]
## The function waits for the game's [signal Node.ready] signal before calling
## [method ArcadeGame.enter].
## [br]
## Emits [signal game_started] after [method ArcadeGame.enter] has been called. [br]
## [br]
## Returns [code]true[/code] if the game was successfully started. [br]
## Returns [code]false[/code] if another game is already running.
func start_game_from_scene(
	gameToLoad : ArcadeGame,
	enterData : Variant = null
) -> bool:
	# GameManager supports only one active ArcadeGame at a time.
	if is_game_running():
		push_error(
			"Attempting to add a new game while another is currently running."
		)
		return false

	# Store ownership of the game before beginning its startup lifecycle.
	currentGame = gameToLoad

	# Listen for requests originating from the game itself.
	currentGame.exit_requested.connect(_on_game_exit_requested)

	# An existing ArcadeGame instance may already belong to another node.
	# Reparent it instead of attempting to add it as a child twice.
	if currentGame.get_parent() != null:
		push_warning(
			"Game to add already has parent: %s. Reparenting."
			% currentGame.get_parent().name
		)
		currentGame.reparent(self)
	else:
		add_child(currentGame)

	# ArcadeGame.enter() must not execute until the game has completed 
	# its normal Node initialization lifecycle.
	await currentGame.ready

	# Forward startup data to the game.
	currentGame.enter(enterData)

	# Inform external systems that the game has started.
	game_started.emit(enterData)

	return true


## Starts an [ArcadeGame] from a [PackedScene]. [br]
## [br]
## [param sceneToLoad] is a previously loaded [PackedScene] containing the
## game to start. [br]
## [br]
## [param enterData] is forwarded to [method start_game_from_scene] and
## eventually to [method ArcadeGame.enter]. [br]
## [br]
## The supplied scene is instantiated and validated before startup. [br]
## The root node of the instantiated scene must inherit from [ArcadeGame]. [br]
## [br]
## Calls [method start_game_from_scene] after successful validation. [br]
## [br]
## Returns [code]true[/code] if the instantiated scene is a valid [br]
## [ArcadeGame] and starts successfully. [br]
## [br]
## Returns [code]false[/code] if the instantiated scene does not inherit from
## [ArcadeGame] or if startup otherwise fails.
func start_game_from_packed_scene(
	sceneToLoad : PackedScene,
	enterData : Variant = null
) -> bool:
	# Instantiate the PackedScene before checking its runtime type.
	var gameScene := sceneToLoad.instantiate()

	# Arcade games must use ArcadeGame as their scene root/base class.
	if gameScene is not ArcadeGame:
		push_error(
			"Invalid packed scene. Expected: ArcadeGame, Recieved: %s"
			% gameScene.get_class()
		)
		return false

	# Delegate the remaining startup lifecycle to the primary startup method.
	return await start_game_from_scene(gameScene, enterData)


## Starts an [ArcadeGame] from a resource path. [br]
## [br]
## [param scenePath] must point to a valid [PackedScene] resource. [br]
## [br]
## [param enterData] is forwarded through [method start_game_from_packed_scene]
## to [method start_game_from_scene], and eventually to
## [method ArcadeGame.enter]. [br]
## [br]
## The method first verifies that the supplied path exists. The resource is
## then loaded and checked to ensure that it is a [PackedScene]. [br]
## [br]
## Calls [method start_game_from_packed_scene] after successfully loading the
## resource. [br]
## [br]
## Returns [code]true[/code] if the path resolves to a valid [ArcadeGame]
## scene and that game starts successfully. [br]
## [br]
## Returns [code]false[/code] andf fails to start an [ArcadeGame] if: [br]
## - The supplied path does not exist. [br]
## - The resource is not a [PackedScene]. [br]
## - The resulting scene does not inherit from [ArcadeGame]. [br]
func start_game_from_path(
	scenePath : String,
	enterData : Variant = null
) -> bool:
	# Reject invalid paths before attempting to load the resource.
	if not FileAccess.file_exists(scenePath):
		push_error("%s not found." % scenePath)
		return false

	# Loading is performed only after confirming that the file exists.
	var packedScene := load(scenePath)

	# Only PackedScenes can be instantiated as ArcadeGame scenes.
	if packedScene is PackedScene:
		return await start_game_from_packed_scene(packedScene, enterData)
	else:
		push_error(
			"Expected: PackedScene, Recieved: %s"
			% packedScene.get_class()
		)
		return false


## Ends the lifecycle of the currently running [ArcadeGame]. [br]
## [br]
## [param exitData] contains optional information forwarded through the exit
## lifecycle. Its structure and meaning are determined by the game and the
## system consuming [signal game_exited]. [br]
## [br]
## The method: [br]
## 1. Verifies that a game is currently running. [br]
## 2. Calls [method ArcadeGame.exit]. [br]
## 3. Queues the game for deletion. [br]
## 4. Waits until the game has left the scene tree. [br]
## 5. Clears [member currentGame]. [br]
## 6. Emits [signal game_exited]. [br]
## [br]
## The local [code]game[/code] reference is retained during cleanup because
## [member currentGame] represents the manager's current lifecycle state and
## is eventually cleared. [br]
## [br]
## Returns [code]true[/code] after a running game has completed its exit
## lifecycle. [br]
## [br]
## Returns [code]false[/code] if no game is currently running.
func exit_game(exitData : Variant = null) -> bool:
	if not is_game_running():
		return false
	# Preserve a local reference throughout the asynchronous exit lifecycle.
	var game := currentGame
	# Allow the game to perform its own shutdown procedure before deletion.
	game.exit()
	# queue_free() schedules the node for deletion at the end of the frame.
	game.queue_free()
	# Wait until the game has actually left the SceneTree before reporting
	# that the exit lifecycle has completed.
	await game.tree_exited
	# GameManager no longer owns an active ArcadeGame.
	currentGame = null
	# Notify external systems that the game has completely exited.
	game_exited.emit(exitData)
	return true


## Returns whether an [ArcadeGame] is currently managed by this node. [br]
## [br]
## Returns [code]true[/code] while [member currentGame] contains an
## [ArcadeGame] reference. [br]
## [br]
## Returns [code]false[/code] when [member currentGame] is [code]null[/code].
func is_game_running() -> bool:
	return currentGame != null


## Handles an exit request emitted by the currently running [ArcadeGame]. [br]
## [br]
## [param exitData] is the data supplied by
## [signal ArcadeGame.exit_requested]. [br]
## [br]
## This method acts as the policy boundary between an [ArcadeGame] requesting
## an exit and [GameManager] actually permitting that exit. [br]
## [br]
## Currently, every exit request is accepted immediately. Future versions may
## add conditions here, such as preventing exit during critical operations,
## requesting confirmation, saving state, or performing transitions.
func _on_game_exit_requested(exitData : Variant) -> void:
	# A future implementation may validate whether the game is currently
	# allowed to exit. For now, every request is accepted.
	exit_game(exitData)
