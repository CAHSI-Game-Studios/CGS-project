class_name ArcadeGame
extends Node2D

signal exit_requested


func request_exit() -> void:
	exit_requested.emit()
