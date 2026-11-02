extends ArcadeGame

#notes are moving icons, that indicate the key to be pressed
#they increase your score when you press their respective key at the right time
@onready var note = preload("res://games/gameB/scenes/Note.tscn")
@onready var minigame_timer = get_node("NoteHandler").get_node("MinigameDuration")
@onready var note_spawner = get_node("NoteHandler").get_node("NoteSpawner")
@onready var note_timer = note_spawner.get_node("SpawnTimer")
#Keep track of the score to determine wether the game was won or lost
var score = 0
#Score required to pass the minigame
#Will be determined by checking the score obtained by the enemy AI
var pass_score =10

#Determines the frequency at which "notes" spawn
#Planned to be replaced in the future with preset note layouts
var note_frequency = 1

#Determines the speed at which "notes" travel
var note_speed = 100


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
	#TODO determine pass score by checking enemy score
	if score >= pass_score:
		print("YOU WIN")
		#TODO insert win logic which increases difficulty, and restarts the game
	else:
		print("YOU LOSE")
		#TODO insert lose logic, offer player choice between retry or exit
		lose_game()
		
#sets obejects to their game start state
func lose_game():
	minigame_timer.start()
	note_timer.wait_time = note_frequency
	note_timer.start()
	score = 0
	


func _on_spawn_timer_timeout() -> void:
	if minigame_timer.time_left > 0:
		var note_instance = note.instantiate() 
		add_child(note_instance)
		note_instance.global_position = note_spawner.global_position 
		note_instance.velocity = note_speed
		
