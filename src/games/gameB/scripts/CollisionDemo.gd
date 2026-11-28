extends Node2D

signal enemy_zone_entered(area: Area2D)
signal note_collided(lane_index: int)
signal gameplay_B_end
signal gameB_win
signal gameB_loss
@onready var note = preload("res://games/gameB/scenes/Note.tscn")

@export var bpm: float = 90.0
@export var action: StringName = &"ui_accept"

const NOTE_RADIUS := 11.0
const NOTE_TEXTURE := preload("res://games/gameB/assets/note.jpg")
const NOTE_LAYER := 1
const TARGET_LAYER := 2
const HIT_LAYER := 4
const BEATS_TO_TARGET := 2

var interval: float = 60.0 / 180.0
var spawn_accumulator := 0.0
var beat_count := 0
var lanes: Array[Dictionary] = []
var lane_directions: Array[Vector2] = []
var note_speed: float = 150.0
var notes: Array[Array] = []
var overlapping_notes: Array[Area2D] = []
var score := 0
var enemy_score := 0
var frequency = 300

#Timing judgement: how far (in seconds) the note is from the hit line when pressed.
#Inside perfect_window = PERFECT, before the line = EARLY, past the line = LATE.
@export var perfect_window: float = 0.04
@export var perfect_points: int = 3
@export var early_late_points: int = 1

const JUDGEMENT_COLORS := {
	"PERFECT": Color(1, 0.85, 0.2),
	"EARLY": Color(0.4, 0.8, 1),
	"LATE": Color(1, 0.55, 0.2),
	"MISS": Color(1, 0.25, 0.25),
}

var perfect_count := 0
var early_count := 0
var late_count := 0
var miss_count := 0
var combo := 0
var judgement_tween: Tween

@onready var score_label: Label = $ScoreDisplay/ScoreLabel
@onready var judgement_label: Label = $ScoreDisplay/JudgementLabel

func _ready() -> void:
	interval = 60.0 / bpm
	$NoteTimer.wait_time = interval
	$NoteTimer.start()
	var longest: float = 0.0
	for lane_node in $Lanes.get_children():
		var spawn: Vector2 = lane_node.get_node("Spawn").global_position
		var target: Vector2 = lane_node.get_node("Target").global_position
		lanes.append({"spawn": spawn, "target": target})
		lane_directions.append((target - spawn).normalized())
		longest = maxf(longest, (target - spawn).length())
	var hit_line: Area2D = $HitLine
	hit_line.area_entered.connect(_on_hit_area_entered)
	hit_line.area_exited.connect(_on_hit_area_exited)
	judgement_label.modulate.a = 0.0
	_update_score_display()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(action):
		_consume_note()
	
		
				
func _consume_note() -> void:
	for area in overlapping_notes:
		for i in range(notes.size()):
			if notes[i][0] == area:
				var lane_index: int = notes[i][1]
				if lane_index != 1:
					break
				_judge_hit(area)
				notes.remove_at(i)
				overlapping_notes.erase(area)
				area.kill()
				_on_note_despawn()
				note_collided.emit(lane_index)
				return

func _judge_hit(area: Area2D) -> void:
	var offset_sec: float = (area.global_position.x - $HitLine.global_position.x) / note_speed
	if absf(offset_sec) <= perfect_window:
		perfect_count += 1
		score += perfect_points
		_register_judgement("PERFECT")
	elif offset_sec < 0.0:
		early_count += 1
		score += early_late_points
		_register_judgement("EARLY")
	else:
		late_count += 1
		score += early_late_points
		_register_judgement("LATE")

func _register_miss() -> void:
	miss_count += 1
	_register_judgement("MISS")

func _register_judgement(judgement: String) -> void:
	combo = 0 if judgement == "MISS" else combo + 1
	judgement_label.text = judgement
	judgement_label.modulate = JUDGEMENT_COLORS[judgement]
	if judgement_tween:
		judgement_tween.kill()
	judgement_tween = create_tween()
	judgement_tween.tween_interval(0.3)
	judgement_tween.tween_property(judgement_label, "modulate:a", 0.0, 0.3)
	_update_score_display()

func _update_score_display() -> void:
	score_label.text = "Score: %d   Combo: %d\nPerfect: %d   Early: %d   Late: %d   Miss: %d" % [
		score, combo, perfect_count, early_count, late_count, miss_count
	]

func _spawn_note(lane_index: int) -> void:
	var notei = note.instantiate()
	notei.velocity = note_speed
	notei.get_node("NoteArea").collision_layer = NOTE_LAYER
	notei.get_node("NoteArea").collision_mask = TARGET_LAYER | HIT_LAYER
	notei.position = lanes[lane_index]["spawn"]
	add_child(notei)
	notei.add_to_group("Notes")
	notes.append([notei.get_node("NoteArea"), lane_index])

func _on_hit_area_entered(area: Area2D) -> void:
	overlapping_notes.append(area)

func _on_hit_area_exited(area: Area2D) -> void:
	overlapping_notes.erase(area)


func _on_game_timer_timeout() -> void:
	$NoteTimer.stop()
	print("MINIGAME OVER")
	if not get_tree().get_nodes_in_group("Notes").is_empty():
		await gameplay_B_end
	
	print(score)
	print(enemy_score)
	if score > enemy_score:
		print("YOU WIN")
		gameB_win.emit()

	else:
		print("YOU LOSE")
		gameB_loss.emit()



func _on_note_timer_timeout() -> void:
	if $GameTimer.time_left > 0.0:
		if randi_range(1,2) == 1:
			_spawn_note(0)
			_spawn_note(1)
			
func _on_note_despawn() -> void:
	if $GameTimer.time_left > 0.0:
		return
	$WaitTimer.wait_time = 1.0
	$WaitTimer.start()
	await $WaitTimer.timeout
	if get_tree().get_nodes_in_group("Notes").is_empty():
		gameplay_B_end.emit()
		print("END")


func _on_target_area_entered(area: Area2D) -> void:
	area.kill() # Replace with function body.
	_on_note_despawn()



func _on_target2_area_entered(area: Area2D) -> void:
	overlapping_notes.erase(area)
	for i in range(notes.size()):
		if notes[i][0] == area:
			notes.remove_at(i)
			break
	_register_miss()
	area.kill()
	_on_note_despawn()
	





func _on_enemy_hit_zone_area_entered(area: Area2D) -> void:
	enemy_zone_entered.emit(area)
