extends Button
class_name ChoiceButton
signal selected(nextDialogue : Dialogue)
var destinationDialogue : Dialogue 

func init(desDialogue : Dialogue, txt : String) -> void:
	self.destinationDialogue = desDialogue
	self.text = txt


func _on_pressed() -> void:
	selected.emit(destinationDialogue)
