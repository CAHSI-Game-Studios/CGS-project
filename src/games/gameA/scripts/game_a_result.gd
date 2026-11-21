class_name GameAResult
extends CanvasLayer

signal retry_requested
signal exit_requested

@onready var title: Label = %Title
@onready var coin_total: Label = %CoinTotal
@onready var retry_button: Button = %Retry
@onready var exit_button: Button = %Exit


func _ready() -> void:
	retry_button.pressed.connect(retry_requested.emit)
	exit_button.pressed.connect(exit_requested.emit)


func show_result(won: bool, coins: int = 0) -> void:
	title.text = "You Won" if won else "You Lost"
	coin_total.visible = won
	if won:
		var coin_name := "coin" if coins == 1 else "coins"
		coin_total.text = "%d %s" % [coins, coin_name]
	retry_button.grab_focus()
