extends Node2D


signal continue_game_b
signal exit_game_b
# 1 = stage_clear, 2 = game_won, 3 = lose
var end_state =0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match end_state:
		1:
			$Label.text = "STAGE CLEAR!!!"
			$GameplayButton.text = "Next Stage"
		2:
			$Label.text = "YOU WIN!!!\nYou now have 2 coins!"
			$GameplayButton.visible = false
		3:
			$Label.text = "YOU LOSE :("
			$GameplayButton.text = "Retry"





func _on_exit_button_pressed() -> void:
	exit_game_b.emit()



func _on_gameplay_button_pressed() -> void:
	continue_game_b.emit()
