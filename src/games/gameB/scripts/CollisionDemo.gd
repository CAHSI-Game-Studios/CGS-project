extends Node2D

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

func _ready() -> void:
	$NoteTimer.wait_time = 1/(frequency / bpm)
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
				notes.remove_at(i)
				overlapping_notes.erase(area)
				area.kill()
				_on_note_despawn()
				score += 1
				note_collided.emit(lane_index)
				return

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
	await gameplay_B_end

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
	area.kill()
	_on_note_despawn()
	
