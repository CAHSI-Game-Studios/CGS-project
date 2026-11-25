extends ArcadeGame

#notes are moving icons, that indicate the key to be pressed
#they increase your score when you press their respective key at the right time
const CUTSCENE_SCENE = preload("res://games/gameB/scenes/BameBIntro.tscn")
@onready var note = preload("res://games/gameB/scenes/Note.tscn")


@onready var gameplay_scene = preload("res://games/gameB/scenes/CollisionDemo.tscn")
@onready var difficulty_select_scene = preload("res://games/gameB/scenes/Difficulty_Select.tscn")
@onready var player = $GameBplayer
@onready var enemy: RhythmEnemy = $player_b_enemy
@onready var end_scene = preload("res://games/gameB/scenes/EndScene.tscn")

#Song played for the whole of game B. Swap it for any AudioStream.
#The player inherits the tree pause, so it stops while the pause menu is open.
@export var music: AudioStream = preload("res://core/music/arcade hub theme.wav"):
	set(value):
		music = value
		if is_node_ready():
			play_music()
@export_range(-80.0, 6.0, 0.1) var music_volume_db: float = -6.0
@onready var music_player: AudioStreamPlayer = $MusicPlayer
#Keep track of the score to determine wether the game was won or lost

#Tells the game to check wether win or lose was achieved


#Determines the frequency at which "notes" spawn
#Planned to be replaced in the future with preset note layouts
var note_frequency = 400

#Determines the speed at which "notes" travel
var note_speed = 300

var remaining_rounds = 2

var current_scene

## Called when the game is added to the scene tree. Note that _ready is called BEFORE enter.
func _ready() -> void:
	music_player.finished.connect(music_player.play)
	enter()

func play_music() -> void:
	if music_player.playing and music_player.stream == music:
		return
	music_player.stream = music
	music_player.volume_db = music_volume_db
	if music:
		music_player.play()
	else:
		music_player.stop()

func begin_gameplay() -> void:
	current_scene = gameplay_scene.instantiate()
	current_scene.note_speed = note_speed
	current_scene.frequency = note_frequency
	current_scene.connect("gameB_win",win_game)
	current_scene.connect("gameB_loss",lose_game)
	add_child(current_scene)
	current_scene.enemy_zone_entered.connect(enemy._on_hit_zone_area_entered)
	enemy.reset()
## Called every physics frame. _delta is the seconds between each frame. 
func _physics_process(_delta: float) -> void:
	pass
## Called by the external system to start the game.
func enter(_enterData: Variant = null) -> void:
	play_music()
	current_scene = CUTSCENE_SCENE.instantiate()
	current_scene.cutscene_finished.connect(_on_cutscene_finished)
	add_child(current_scene)
## Called by the external system before unloading. Each game is responsible for defining their exit function.
func exit() -> void:
	music_player.stop()
	if remaining_rounds<=0:
		Global.currency += 1
	request_exit()
	
	

## Called by the game when it wants to close.
func request_exit(_exitData : Variant = null) -> void:
	exit_requested.emit(_exitData)

#Game currently runs for 10 seconds before ending

		
#sets obejects to their game start state
func lose_game():
	change_to_end_scene(3)
	print("LOSE")
	



		




func win_game():
	
	#note_speed +=20
	#Add logic to return to difficulty select scene
	#Currently only sends the request_exit signal
	if remaining_rounds <=0:
		change_to_end_scene(2)
	else:
		change_to_end_scene(1)
		note_speed += 20
		remaining_rounds -=1
		enemy.reset()
		to_difficulty_select()
	
	
	
func to_difficulty_select():
	print("Changing to difficulty select")

	if is_instance_valid(current_scene):
		current_scene.queue_free()

	current_scene = difficulty_select_scene.instantiate()
	
	current_scene.difficulty_selected.connect(_on_difficulty_selected)
	add_child(current_scene)

func _on_difficulty_selected(difficulty: int) -> void:

	var selected_bpm: float

	match difficulty:
		0:
			selected_bpm = 90.0
		1:
			selected_bpm = 120.0
		2:
			selected_bpm = 180.0

	start_gameplay(selected_bpm)
#tests if the player pressed the key

func _on_game_bplayer_lane_pressed(note_index: int) -> void:
	print("Interaction signal received correctly Lane: ", note_index)


func _on_enemy_score_changed(new_score: int) -> void:
	print("Enemy score: ", new_score)
	if current_scene and "enemy_score" in current_scene:
		current_scene.enemy_score = new_score
	
func _on_cutscene_finished() -> void:
	current_scene.queue_free()
	current_scene = null
	to_difficulty_select()

func change_to_end_scene(state):
	current_scene.queue_free()
	current_scene = end_scene.instantiate()
	current_scene.end_state = state
	current_scene.connect("exit_game_b", player_choose_exit)
	current_scene.connect("continue_game_b", to_difficulty_select)
	add_child(current_scene)
	
func player_choose_exit():
	exit()
	
func start_gameplay(selected_bpm: float) -> void:

	current_scene.queue_free()

	current_scene = gameplay_scene.instantiate()

	current_scene.bpm = selected_bpm
	current_scene.note_speed = note_speed
	current_scene.frequency = note_frequency

	current_scene.gameB_win.connect(win_game)
	current_scene.gameB_loss.connect(lose_game)

	add_child(current_scene)
