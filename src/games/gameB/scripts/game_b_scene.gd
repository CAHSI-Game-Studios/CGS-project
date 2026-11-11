extends ArcadeGame

#notes are moving icons, that indicate the key to be pressed
#they increase your score when you press their respective key at the right time
@onready var note = preload("res://games/gameB/scenes/Note.tscn")
@onready var minigame_timer = get_node("NoteHandler").get_node("MinigameDuration")
@onready var note_spawner = get_node("NoteHandler").get_node("NoteSpawner")
@onready var note_timer = note_spawner.get_node("SpawnTimer")
@onready var player = $GameBplayer
#Keep track of the score to determine wether the game was won or lost
var score = 20
#Score required to pass the minigame
#Will be determined by checking the score obtained by the enemy AI
var pass_score =10

#Tells the game to check wether win or lose was achieved
signal gameplay_B_end

#Determines the frequency at which "notes" spawn
#Planned to be replaced in the future with preset note layouts
var note_frequency = 1

#Determines the speed at which "notes" travel
var note_speed = 300


## Called when the game is added to the scene tree. Note that _ready is called BEFORE enter.
func _ready() -> void:
	#temporary boot-up will be replaced with code that does not start the player immediately in the game portion
	lose_game()
## Called every physics frame. _delta is the seconds between each frame. 
func _physics_process(_delta: float) -> void:
	pass
## Called by the external system to start the game.
func enter( _enterData : Variant = null) -> void:
	pass
## Called by the external system before unloading. Each game is responsible for defining their exit function.
func exit() -> void:
	request_exit()
	
	

## Called by the game when it wants to close.
func request_exit(_exitData : Variant = null) -> void:
	exit_requested.emit(_exitData)

#Game currently runs for 10 seconds before ending
func _on_minigame_duration_timeout() -> void:
	note_timer.stop()
	print("MINIGAME OVER")
	await gameplay_B_end
	print(score >= pass_score)
	if score >= pass_score:
		print("YOU WIN")
		win_game()

	else:
		print("YOU LOSE")
		lose_game()
		
#sets obejects to their game start state
func lose_game():
	minigame_timer.start()
	note_timer.wait_time = note_frequency
	note_timer.start()
	score = 20
	


func _on_spawn_timer_timeout() -> void:
	if minigame_timer.time_left > 0:
		var note_instance = note.instantiate() 
		add_child(note_instance)
		note_instance.global_position = note_spawner.global_position 
		note_instance.velocity = note_speed
		note_instance.add_to_group("Notes")
		


func _on_note_despawner_area_entered(area: Area2D) -> void:
	#Created a pre-existing timer to avoid creating one during runtime
	#The timer can be used for multiple things
	
	#The timer is necessary to allow notes to despawn before checking if there are no notes
	$WaitTime.wait_time = 1.0
	$WaitTime.start()
	await $WaitTime.timeout
	if get_tree().get_nodes_in_group("Notes").is_empty():
		gameplay_B_end.emit()

func win_game():
	#note_speed +=10
	#Add logic to return to difficulty select scene
	#Currently only sends the request_exit signal
	exit()
#tests if the player pressed the key

func _on_game_bplayer_lane_pressed(note_index: int) -> void:
	print("Interaction signal received correctly Lane: ", note_index)
