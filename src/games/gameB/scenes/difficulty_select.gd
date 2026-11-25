extends Control

signal difficulty_selected(difficulty: int)


func _on_easy_pressed() -> void:
	difficulty_selected.emit(0)


func _on_medium_pressed() -> void:
	difficulty_selected.emit(1)


func _on_hard_pressed() -> void:
	difficulty_selected.emit(2)
