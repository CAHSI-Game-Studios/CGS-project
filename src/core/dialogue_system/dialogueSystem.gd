extends Control
class_name DialogueSystem


var choiceButtonScene : PackedScene = preload("res://core/dialogue_system/choiceButton.tscn")
@onready var dialogue_text: RichTextLabel = $dialogueBox/dialogueText

var currentDialogue : Dialogue
var canSkipCurrentDialogue : bool = false

func closeSystem() -> void:
	self.visible = false
	currentDialogue = null
	set_process(false)
func openSystem() -> void:
	canSkipCurrentDialogue = false
	set_process(true)
	self.visible = true
func getCurrentDialogue() -> Dialogue:
	return currentDialogue
func setCurrentDialogue(newDialogue : Dialogue) -> void:
	currentDialogue = null
	canSkipCurrentDialogue = false
	for child in $dialogueBox/choiceButtons.get_children():
		$dialogueBox/choiceButtons.remove_child(child)
	if newDialogue:
		canSkipCurrentDialogue = false
		currentDialogue = newDialogue
		$dialogueBox/speaker.text = currentDialogue.speaker
		dialogue_text.visible_characters = 0
		dialogue_text.visible_ratio = 0
		dialogue_text.text = newDialogue.text
		if currentDialogue is ChoiceDialogue:
			for key in currentDialogue.responses.keys():
				var newButton : ChoiceButton = choiceButtonScene.instantiate()
				newButton.init(currentDialogue.responses[key],key)
				newButton.selected.connect(setCurrentDialogue)
				$dialogueBox/choiceButtons.add_child(newButton)
	else:
		push_error("Invalid (null) new dialogue being set.")
func _process(_delta: float) -> void:
	if currentDialogue:
		dialogue_text.visible_characters = min(currentDialogue.text.length(), dialogue_text.visible_characters + 1*currentDialogue.textSpeed)
		if dialogue_text.visible_ratio >= currentDialogue.allowSkipAt:
			canSkipCurrentDialogue = true
			if currentDialogue is ChoiceDialogue:
				$dialogueBox/choiceButtons.visible = true

func _on_dialogue_box_gui_input(event: InputEvent) -> void:
	if !visible:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && canSkipCurrentDialogue:
			if currentDialogue is LinearDialogue:
				setCurrentDialogue(currentDialogue.nextDialogue)
			elif currentDialogue is EndingDialogue:
				closeSystem()
			elif currentDialogue is ChoiceDialogue:
				return
