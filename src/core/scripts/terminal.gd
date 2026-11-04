extends Window
class_name DebugTerminal

@export_group("Games")
@export var game_manager : GameManager
@export var games : Dictionary[String, PackedScene]
@export_group("Dialogues")
@export var dialogue_system : DialogueSystem
@export var test_dialogues : Dictionary[String, Dialogue]

@onready var output: Label = $Control/VBoxContainer/ScrollContainer2/output
@onready var input: LineEdit = $Control/VBoxContainer/input

func logLine(line : String) -> void:
	output.text += "\n%s" % line 

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
			Command Alias Functtion
			
			game_manager   gm           Provides an interface into the GameManager.
			-start         s            Calls one of GameManager's start_game methods.
			--"[key]"                   Starts a game at [key] from the valid games.
			--"path:[p]"                Starts a game from a given path.
			-games         gms          Returns an array of valid game string ID's.
			-exit          e            Stops the current active game.
			
			dialogue_system   ds        Provides an interface into the DialogueSystem.
			-open             o         Enables the visibility and processing of the dialogue system.
			-close            c         Disables the visibility and processing of the dialogue system.
			-set              s         Sets the next dialogue to be displayed.
			--[key]                     Sets the dialogue at key [key] from the valid dialogues.
			--path:[p]                  Sets the dialogue at path [p].
			-dialogues        dgs       Returns an array of valid dialogue ID's.
			 
	
			stop                        Quits the entire project.
			help           ?            Provides a list of commands.

			""")
			
		"game_manager","gm":
			currentWord += 1
			if currentWord <= inputSize:
				match inputs[1]:
					"start","s":
						currentWord+=1
						if currentWord <= inputSize:
							if games.has(inputs[currentWord]):
								game_manager.start_game_from_packed_scene(games[inputs[currentWord]])
							elif inputs[currentWord].begins_with("path:"):
								var path : String = inputs[currentWord].replace("path:", "")
								game_manager.start_game_from_path(path)
					"exit","e":
						game_manager._on_game_exit_requested(null)
					"gms","games":
						logLine(str(games.keys()))
					_:
						logLine("Unrecognized command. Enter help or ? for command list.")
		"dialogue_system", "ds":
			currentWord += 1
			if currentWord <= inputSize:
				match inputs[1]:
					"close", "c":
						dialogue_system.closeSystem()
					"open", "o":
						dialogue_system.openSystem()
					"set", "s":
						currentWord += 1
						if currentWord <= inputSize:
							if inputs[currentWord].begins_with("path:"):
								var pth : String = inputs[currentWord].replace("path:","")
								if ResourceLoader.exists(pth):
									var dlg :=  ResourceLoader.load(pth)
									if dlg is Dialogue:	
										dialogue_system.setCurrentDialogue(dlg)
									else:
										logLine("Path: %s does not return a valid Dialogue resoure." % pth)
								else:
										logLine("Path: %s does not exists." % pth)
							elif test_dialogues.has(inputs[currentWord]):
								dialogue_system.setCurrentDialogue(test_dialogues[inputs[currentWord]])
							else:
								logLine("Unrecognized command. Enter help or ? for command list.")
								
					"dialogues", "dgs":
						logLine(str(test_dialogues.keys()))
					_:
						logLine("Unrecognized command. Enter help or ? for command list.")
		
		"stop":
			get_tree().quit(Error.OK)
		_:
			logLine("Unrecognized command. Enter help or ? for command list.")

func _on_close_requested() -> void:
	hide()
