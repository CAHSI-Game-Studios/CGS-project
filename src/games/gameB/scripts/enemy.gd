extends Node2D

enum Difficulty { EASY, MEDIUM, HARD }
@export var difficulty: Difficulty = Difficulty.MEDIUM

var enemy_score: int = 0
var hit_chance: float = 0.75

func _ready() -> void:
	setup_difficulty()

func setup_difficulty() -> void:
	match difficulty:
		Difficulty.EASY:
			hit_chance = 0.5
		Difficulty.MEDIUM:
			hit_chance = 0.75
		Difficulty.HARD:
			hit_chance = 0.95

func _on_hit_zone_area_entered(area: Area2D) -> void:
	if not area.is_in_group("Notes"):
		return
	if randf() < hit_chance:
		enemy_score += 1

func get_enemy_score() -> int:
	return enemy_score

func reset() -> void:
	enemy_score = 0
