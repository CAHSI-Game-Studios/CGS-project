extends Node2D

enum Difficulty { EASY, MEDIUM, HARD }
@export var difficulty: Difficulty = Difficulty

var enemy_score: int = 0
@onready var check_timer: Timer = $CheckTimer

func _ready() -> void:
	setup_difficulty()
	check_timer.start()

func setup_difficulty() -> void:
	match difficulty:
		Difficulty.EASY:
			check_timer.wait_time = 1.2
		Difficulty.MEDIUM:
			check_timer.wait_time = 0.8
		Difficulty.HARD:
			check_timer.wait_time = 0.4

# check if a note is near the hit line to hit it
func _on_check_timer_timeout() -> void:
	var active_notes = get_tree().get_nodes_in_group("Notes")
	
	for note_node in active_notes:
		# Check if the note is close to the enemy's hit position
		var distance = note_node.global_position.distance_to(global_position)
		
		if distance < 60.0:
			enemy_score += 1
			print("Enemy hit a note! Score: ", enemy_score)
			note_node.queue_free() # Enemy clears the note
			break

func get_enemy_score() -> int:
	return enemy_score
