extends Node2D

signal note_collided(lane_index: int)

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
var note_speed: float = 0.0
var notes: Array[Array] = []
var overlapping_notes: Array[Area2D] = []
var score := 0

func _ready() -> void:
	interval = 60.0 / bpm
	var longest: float = 0.0
	for lane_node in $Lanes.get_children():
		var spawn: Vector2 = lane_node.get_node("Spawn").global_position
		var target: Vector2 = lane_node.get_node("Target").global_position
		lanes.append({"spawn": spawn, "target": target})
		lane_directions.append((target - spawn).normalized())
		longest = maxf(longest, (target - spawn).length())
	note_speed = longest / (BEATS_TO_TARGET * interval)
	var hit_line: Area2D = $HitLine
	hit_line.area_entered.connect(_on_hit_area_entered)
	hit_line.area_exited.connect(_on_hit_area_exited)
	spawn_accumulator = interval

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(action):
		_consume_note()
	spawn_accumulator -= delta
	while spawn_accumulator <= 0.0:
		spawn_accumulator += interval
		_spawn_note(beat_count % lanes.size())
		beat_count += 1
	for i in range(notes.size() - 1, -1, -1):
		var note: Area2D = notes[i][0]
		var lane_index: int = notes[i][1]
		note.position += lane_directions[lane_index] * note_speed * delta
		var remaining: float = lanes[lane_index]["target"].distance_to(note.position)
		if remaining < note_speed * delta:
			notes.remove_at(i)
			overlapping_notes.erase(note)
			note.queue_free()

func _consume_note() -> void:
	for area in overlapping_notes:
		for i in range(notes.size()):
			if notes[i][0] == area:
				var lane_index: int = notes[i][1]
				if lane_index != 1:
					break
				notes.remove_at(i)
				overlapping_notes.erase(area)
				area.queue_free()
				score += 1
				note_collided.emit(lane_index)
				return

func _spawn_note(lane_index: int) -> void:
	var note := Area2D.new()
	note.collision_layer = NOTE_LAYER
	note.collision_mask = TARGET_LAYER | HIT_LAYER
	note.position = lanes[lane_index]["spawn"]
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = NOTE_RADIUS
	shape.shape = circle
	note.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = NOTE_TEXTURE
	sprite.scale = Vector2(0.055, 0.055)
	note.add_child(sprite)
	add_child(note)
	notes.append([note, lane_index])

func _on_hit_area_entered(area: Area2D) -> void:
	overlapping_notes.append(area)

func _on_hit_area_exited(area: Area2D) -> void:
	overlapping_notes.erase(area)
