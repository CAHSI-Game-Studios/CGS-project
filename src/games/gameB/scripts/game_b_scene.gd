extends ArcadeGame

#notes are moving icons, that indicate the key to be pressed
#they increase your score when you press their respective key at the right time


@onready var gameplay_scene = preload("res://games/gameB/scenes/CollisionDemo.tscn")
@onready var difficulty_select_scene = preload("res://games/gameB/scenes/Difficulty_Select.tscn")
@onready var player = $GameBplayer
@onready var end_scene = preload("res://games/gameB/scenes/EndScene.tscn")
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
	to_difficulty_select()
## Called every physics frame. _delta is the seconds between each frame. 
func _physics_process(_delta: float) -> void:
	pass
## Called by the external system to start the game.
func enter( _enterData : Variant = null) -> void:
	pass
## Called by the external system before unloading. Each game is responsible for defining their exit function.
func exit() -> void:
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
