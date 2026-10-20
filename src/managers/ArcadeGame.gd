class_name ArcadeGame
extends Node




## Base class for all minigames in The Arcade.
##
## Every arcade minigame must inherit from ArcadeGame.
##
## Lifecycle contract:
## 1. An external system instantiates the game scene.
## 2. The external system adds the game to the scene tree.
## 3. The external system calls enter() to start the game.
## 4. The game emits exit_requested when it wants to close.
## 5. The external system calls exit() and unloads the game.
##
## ArcadeGame never changes scenes or unloads itself.
## It has no knowledge of the Hub or game coordinator.


## Emitted when the game has started.
signal game_started

## Emitted when the game wants to close.
signal exit_requested

## Emitted when the game has completed its exit lifecycle.
signal game_exited


## Called by the external system to start the game.
func enter() -> void:
	game_started.emit()


## Called by the external system before unloading.
func exit() -> void:
	game_exited.emit()


## Called by the game when it wants to close.
func request_exit() -> void:
	exit_requested.emit()
