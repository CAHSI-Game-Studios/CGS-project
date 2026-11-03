
# Author: nu-hazd, rev: Oct 23, 2026
extends Control
class_name DialogueSystem
## Controls the presentation and progression of dialogue.
##
## Expected scene structure:
##
## [codeblock]
## DialogueSystem
## └── dialogueBox
##     ├── dialogueText
##     ├── ChoiceButtonContainer
##     └── speaker
##     └── icon
## [/codeblock]
##
## The system displays [Dialogue] resources, progressively reveals their text,
## creates response buttons for choice dialogues, and determines how dialogue
## progresses based on [member Dialogue.dialogue_type]. [br]
## [br]
## Supported dialogue types: [br]
## - [constant Dialogue.TYPE.LINEAR]: progresses to [member Dialogue.nextDialogue]. [br]
## - [constant Dialogue.TYPE.CHOICE]: displays buttons from [member Dialogue.responses]. [br]
## - [constant Dialogue.TYPE.ENDING]: closes the dialogue system. [br]
## [br]
## The dialogue system does not create or modify dialogue data. It only
## interprets [Dialogue] resources and presents them to the player.


## Scene used to create selectable responses for choice dialogues.
## [br]
## Each instantiated scene is expected to use [ChoiceButton] as its root
## script and provide:
## - [method ChoiceButton.init]
## - [signal ChoiceButton.selected]
var choice_button_scene : PackedScene = preload( "res://core/dialogue_system/choiceButton.tscn")
## Label responsible for displaying the current dialogue text.
##
## The label's [member RichTextLabel.visible_ratio] is modified every frame
## to create the gradual text-reveal effect.
@export var dialogue_text : RichTextLabel


## Container responsible for holding dynamically created [ChoiceButton] nodes.
##
## Children are generated whenever the current dialogue is a choice dialogue
## and removed whenever the dialogue changes or the system is cleared.
@export var choice_button_container : VBoxContainer


## Label responsible for displaying the name of the current speaker.
@export var speaker : RichTextLabel


## Dialogue resource currently being displayed.
##
## Contains [code]null[/code] when no dialogue is active.
var current_dialogue : Dialogue


## Determines whether the player may currently advance or interact with the
## active dialogue.
##
## This becomes [code]true[/code] once the amount of revealed text reaches
## [member Dialogue.allow_skip_at].
var can_skip_current_dialogue : bool = false


## Initializes the dialogue system.
##
## Processing begins disabled because no dialogue is assumed to be active when
## the node enters the scene tree.
##
## [method open_system] enables processing when the dialogue interface is used.
func _ready() -> void:
	set_process(false)


## Closes the dialogue interface and resets its current state. [br]
##[br]
## Calls [method clear_system], hides the [DialogueSystem], and disables
## frame processing.[br]
## [br] 
## After this method completes: [br] 
## - [member current_dialogue] is [code]null[/code].[br]
## - Dialogue progression is disabled.[br]
## - Existing choice buttons have been removed.[br]
## - The dialogue interface is hidden.[br]
func close_system() -> void:
	clear_system()
	self.visible = false
	set_process(false)


## Opens the dialogue interface.[br]
##[br]
## Resets dialogue skipping, enables frame processing, and makes the dialogue
## interface visible.[br]
##[br]
## This method does not assign a dialogue. Use [method set_current_dialogue]
## to select the dialogue that should be displayed.
func open_system() -> void:
	can_skip_current_dialogue = false
	set_process(true)
	self.visible = true


## Returns the dialogue currently displayed by the system.
##
## Returns the active [Dialogue], or [code]null[/code] if no dialogue is
## currently assigned.
func get_current_dialogue() -> Dialogue:
	return current_dialogue


## Clears all temporary state associated with the current dialogue.
##
## The current dialogue reference and skip state are reset.
##
## All children currently stored inside
## [member choice_button_container] are removed from the container.
##
## This method does not hide the dialogue system or disable processing.
func clear_system() -> void:
	current_dialogue = null
	can_skip_current_dialogue = false

	for child in choice_button_container.get_children():
		choice_button_container.remove_child(child)


## Replaces the currently displayed dialogue.[br]
##[br]
## [param newDialogue] is the [Dialogue] resource that should become active.[br]
##[br]
## The previous dialogue state is cleared before the new dialogue is assigned.
## The speaker and dialogue labels are then populated from the new resource.
##[br]
## Dialogue text begins with a [member RichTextLabel.visible_ratio] of
## [code]0[/code] so that [method _process] may progressively reveal it.
##[br]
## If [param newDialogue] is a choice dialogue, one [ChoiceButton] is created
## for every entry in [member Dialogue.responses].
##[br]
## Each response dictionary entry is interpreted as:
##[br]
## [codeblock]
## response text -> next Dialogue
## [/codeblock]
##[br]
## Each generated button emits its selected dialogue back into this method,
## allowing dialogue branches to reuse the same display logic.
## [br]
## Passing [code]null[/code] reports an error and leaves the system without
## an active dialogue. Returning [code]false[/code] if the newDialogue is [code]null[/code], returns [code]true[/code] otherwise.
func set_current_dialogue(newDialogue : Dialogue) -> bool:
	clear_system()
	if newDialogue:
		can_skip_current_dialogue = false
		current_dialogue = newDialogue

		# Display the current speaker.
		speaker.text = current_dialogue.speaker

		# Reset the typewriter effect before assigning the new text.
		dialogue_text.visible_ratio = 0
		dialogue_text.text = newDialogue.text

		# Choice dialogues dynamically generate one button for each response.
		if current_dialogue.dialogue_type == Dialogue.TYPE.CHOICE:
			for key in current_dialogue.responses.keys():
				var newButton : ChoiceButton = choice_button_scene.instantiate()

				# The response's target dialogue and displayed text are passed
				# into the newly created ChoiceButton.
				newButton.init(current_dialogue.responses[key], key)

				# Selecting a response immediately makes its associated
				# Dialogue the current dialogue.
				newButton.selected.connect(set_current_dialogue)

				choice_button_container.add_child(newButton)
			return true
	else:
		push_error("Invalid (null) new dialogue being set.")
	return false


## Updates the text-reveal effect for the active dialogue. [br]
## 
## [param delta] is the elapsed time in seconds since the previous frame.
##
## Text is revealed by increasing [member RichTextLabel.visible_ratio]
## according to [member Dialogue.text_duration].
##
## Once the visible ratio reaches [member Dialogue.allow_skip_at],
## [member can_skip_current_dialogue] becomes [code]true[/code].
##
## For choice dialogues, the choice container becomes visible at the same
## point, allowing the player to select a response.
func _process(delta : float) -> void:
	if current_dialogue:
		dialogue_text.visible_ratio = max(
			0,
			dialogue_text.visible_ratio
			+ delta / current_dialogue.text_duration
		)

		if dialogue_text.visible_ratio >= current_dialogue.allow_skip_at:
			can_skip_current_dialogue = true

			if current_dialogue.dialogue_type == Dialogue.TYPE.CHOICE:
				choice_button_container.visible = true


## Handles mouse input received by the dialogue box.
## [br]
## Input is ignored while the dialogue system is hidden. [br]
## [br]
## Once [member can_skip_current_dialogue] is [code]true[/code], a left mouse
## click performs an action based on the current dialogue type: [br]
## [br]
## [b]Linear[/b] [br]
## Advances to [member Dialogue.nextDialogue]. [br]
##[br]
## [b]Ending[/b] [br]
## Closes the dialogue system. [br]
##[br] 
## [b]Choice[/b][br]
## Immediately reveals all remaining dialogue text. Progression then occurs
## through the dynamically generated [ChoiceButton] nodes rather than through
## clicking the dialogue box itself.
func _on_dialogue_box_gui_input(event : InputEvent) -> void:
	# Ignore dialogue input while the interface is closed.
	if !visible:
		return
	if event is InputEventMouseButton:
		if (
			event.button_index == MOUSE_BUTTON_LEFT
			&& can_skip_current_dialogue
		):
			match current_dialogue.dialogue_type:
				Dialogue.TYPE.LINEAR:
					set_current_dialogue(
						current_dialogue.next_dialogue
					)

				Dialogue.TYPE.ENDING:
					close_system()

				Dialogue.TYPE.CHOICE:
					dialogue_text.visible_ratio = 1.0
