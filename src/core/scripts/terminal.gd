extends Window
class_name DebugTerminal

@export var game_manager : GameManager
@export var games : Array[PackedScene]
@onready var output: Label = $Control/VBoxContainer/ScrollContainer2/output
@onready var input: LineEdit = $Control/VBoxContainer/input

func logLine(line : String) -> void:
	output.text += "\n %s" % line 

func _on_input_text_submitted(inputText: String) -> void:
	if inputText.length() == 0:
		return
	if inputText.length() > 64:
		logLine("Invalid input size.")
		return
	input.clear()
	logLine(inputText)
	parseInput(inputText)
	
func parseInput( inputText : String) -> void:
	var inputs : PackedStringArray = inputText.split(" ")
	var inputSize : int = inputs.size()
	var currentWord : int = 0
	match inputs[0]:
		"help", "?":
			logLine("""
				game_manager load,start [num]- starts the game at index num
				game_manager load,start [path]- starts the game at specified path
				game_manager exit,quit- exits the current game
				game_manager valid,games- returns list of valid indexes
				help, ?- display command list
				stop- terminates main scene
			""")
			
		"game_manager","gm":
			currentWord += 1
			if currentWord <= inputSize:
				match inputs[1]:
					"load","start","s":
						currentWord+=1
						if currentWord <= inputSize:
							if inputs[currentWord].is_valid_int():
								if int(inputs[currentWord]) <= games.size():
									game_manager.start_game_from_packed_scene(games[int(inputs[currentWord])])
							elif inputs[currentWord].begins_with("path:"):
								var path : String = inputs[currentWord].replace("path:", "")
								game_manager.start_game_from_path(path)
					"quit", "exit","q":
						game_manager._on_game_exit_requested(null)
					"valid","games":
						var valids : Array = []
						for i in range(games.size()):
							valids.push_back(i)
						logLine(str(valids))
		"stop":
			get_tree().quit(Error.OK)
		_:
			logLine("Unrecognized command. Enter help or ? for command list.")

func _on_close_requested() -> void:
	hide()
