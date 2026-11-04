@abstract class_name ArcadeGame
extends Node
## Base class for all minigames in The Arcade.
##
## Every arcade minigame must inherit from ArcadeGame.
##
## Lifecycle contract: [br]
## 1. An external system instantiates the game scene. [br]
## 2. The external system adds the game to the scene tree. [br]
## 3. The external system calls enter() to start the game. [br]
## 4. The game emits exit_requested when it wants to close. [br]
## 5. The external system calls exit() and unloads the game. [br]
##
## ArcadeGame never changes scenes or unloads itself.
## It has no knowledge of the Hub or game coordinator.


## Emitted when the game wants to close.
signal exit_requested

# -= VIRTUAL METHODS =- 
# Each game MUST define each of these four methods.
## Called when the game is added to the scene tree. Note that _ready is called BEFORE enter.
@abstract func _ready() -> void
## Called every physics frame. _delta is the seconds between each frame. 
@abstract func _physics_process(_delta: float) -> void
## Called by the external system to start the game.
func enter( _enterData : Variant = null) -> void:
	pass
## Called by the external system before unloading. Each game is responsible for defining their exit function.
func exit() -> void:
	pass

## Called by the game when it wants to close.
func request_exit(_exitData : Variant = null) -> void:
	exit_requested.emit(_exitData)
