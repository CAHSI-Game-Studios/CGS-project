class_name RhythmEnemy
extends Node2D

signal score_changed(new_score: int)

enum Difficulty { EASY, MEDIUM, HARD }

@export var difficulty: Difficulty = Difficulty.MEDIUM:
	set(value):
		difficulty = value
		setup_difficulty()

@onready var hit_zone: Area2D = get_node_or_null("HitZone")

var enemy_score: int = 0
var hit_chance: float = 0.75
var _hit_note_ids: Dictionary = {}

func _ready() -> void:
	setup_difficulty()
	if hit_zone and not hit_zone.area_entered.is_connected(_on_hit_zone_area_entered):
		hit_zone.area_entered.connect(_on_hit_zone_area_entered)

func setup_difficulty() -> void:
	match difficulty:
		Difficulty.EASY:
			hit_chance = 0.5
		Difficulty.MEDIUM:
			hit_chance = 0.75
		Difficulty.HARD:
			hit_chance = 0.95

func _on_hit_zone_area_entered(area: Area2D) -> void:
	if not is_instance_valid(area) or not area.get_parent().is_in_group("Notes"):
		return

	var note_id: int = area.get_instance_id()
	if _hit_note_ids.has(note_id):
		return
	_hit_note_ids[note_id] = true

	if randf() < hit_chance:
		enemy_score += 1
		score_changed.emit(enemy_score)
		if area.has_method("on_enemy_hit"):
			area.on_enemy_hit()

func get_enemy_score() -> int:
	return enemy_score

func reset() -> void:
	enemy_score = 0
	_hit_note_ids.clear()
	score_changed.emit(enemy_score)
