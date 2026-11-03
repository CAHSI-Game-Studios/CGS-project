extends Node2D

signal note_collided(lane_index: int)

@export var bpm: float = 90.0
@export var action: StringName = &"ui_accept"

const LANES: Array[Dictionary] = [
	{"spawn": Vector2(80, 110), "target": Vector2(1200, 110)},
	{"spawn": Vector2(80, 230), "target": Vector2(1200, 230)},
]
const BAR_HEIGHT := 28.0
const NOTE_RADIUS := 11.0
const NOTE_TEXTURE := preload("res://games/gameB/assets/note.jpg")
const TARGET_RADIUS := 26.0
const HIT_X := 640.0
const HIT_WIDTH := 8.0
const HIT_HALF_WIDTH := HIT_WIDTH / 2.0
const NOTE_LAYER := 1
const TARGET_LAYER := 2
const BEATS_TO_TARGET := 2

var interval: float = 60.0 / 180.0
var spawn_accumulator := 0.0
var beat_count := 0
var lane_directions: Array[Vector2] = []
var note_speeds: Array[float] = []
var notes: Array[Array] = []
var score := 0

func _ready() -> void:
	interval = 60.0 / bpm
	for lane in LANES:
		var bar := ColorRect.new()
		bar.color = Color.WHITE
		bar.position = Vector2(lane["spawn"].x, lane["spawn"].y - BAR_HEIGHT / 2.0)
		bar.size = Vector2(lane["target"].x - lane["spawn"].x, BAR_HEIGHT)
		add_child(bar)
		add_child(_create_target(lane["target"]))
		var direction: Vector2 = (lane["target"] - lane["spawn"]).normalized()
		lane_directions.append(direction)
		var length: float = (lane["target"] - lane["spawn"]).length()
		note_speeds.append(length / (BEATS_TO_TARGET * interval))
	spawn_accumulator = interval
	var hit_line := ColorRect.new()
	hit_line.color = Color.RED
	hit_line.position = Vector2(HIT_X - HIT_HALF_WIDTH, 96.0)
	hit_line.size = Vector2(HIT_WIDTH, 244.0 - 96.0)
	add_child(hit_line)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(action):
		_consume_note()
	spawn_accumulator -= delta
	while spawn_accumulator <= 0.0:
		spawn_accumulator += interval
		_spawn_note(beat_count % LANES.size())
		beat_count += 1
	for i in range(notes.size() - 1, -1, -1):
		var note: Area2D = notes[i][0]
		var lane_index: int = notes[i][1]
		note.position += lane_directions[lane_index] * note_speeds[lane_index] * delta
		var remaining: float = LANES[lane_index]["target"].distance_to(note.position)
		if remaining < note_speeds[lane_index] * delta:
			notes.remove_at(i)
			note.queue_free()

func _consume_note() -> void:
	for i in range(notes.size()):
		var note: Area2D = notes[i][0]
		var lane_index: int = notes[i][1]
		if lane_index != 1:
			continue
		if absf(note.position.x - HIT_X) <= HIT_HALF_WIDTH + NOTE_RADIUS:
			notes.remove_at(i)
			note.queue_free()
			score += 1
			note_collided.emit(lane_index)
			return

func _spawn_note(lane_index: int) -> void:
	var note := Area2D.new()
	note.collision_layer = NOTE_LAYER
	note.collision_mask = TARGET_LAYER
	note.position = LANES[lane_index]["spawn"]
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = NOTE_RADIUS
	shape.shape = circle
	note.add_child(shape)
	var sprite := Sprite2D.new()
	sprite.texture = NOTE_TEXTURE
	sprite.scale = Vector2(0.055, 0.055)
	note.add_child(sprite)
	note.area_entered.connect(_on_note_area_entered.bind(lane_index, note))
	add_child(note)
	notes.append([note, lane_index])

func _on_note_area_entered(_area: Area2D, lane_index: int, note: Area2D) -> void:
	note_collided.emit(lane_index)
	for i in range(notes.size()):
		if notes[i][0] == note:
			notes.remove_at(i)
			break
	note.queue_free()

func _create_target(target_position: Vector2) -> Area2D:
	var target := Area2D.new()
	target.collision_layer = TARGET_LAYER
	target.collision_mask = 0
	target.position = target_position
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = TARGET_RADIUS
	shape.shape = circle
	target.add_child(shape)
	return target
