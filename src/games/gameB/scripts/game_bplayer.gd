extends Node2D

# Declare signals that the main scene can listen to
signal lane_pressed(note_index: int)

# Array mapping lane indices to your input actions
const NOTE_ACTIONS: Array[String] = [
	"s_note", # s
	"d_note", # d
	"j_note", # j
	"k_note"  # k
]

func _input(event: InputEvent) -> void:
	for i in range(NOTE_ACTIONS.size()):
		if event.is_action_pressed(NOTE_ACTIONS[i]):
			# Emit the signal passing the lane index
			lane_pressed.emit(i)
			
			# Mark input as handled so other nodes don't re-trigger it
			get_viewport().set_input_as_handled()
			break
