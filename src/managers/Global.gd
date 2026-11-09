extends Node
var currency: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func update_currency(amount: int = 1) -> void:
	currency += amount
	
func get_currency() -> int: 
	return currency 
