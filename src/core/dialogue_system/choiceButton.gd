extends Button
class_name ChoiceButton

signal selected(next_dialogue : Dialogue)
var destination_dialogue : Dialogue

func init(des_dialogue : Dialogue, txt : String) -> void:
	self.destination_dialogue = des_dialogue
	self.text = txt

func _on_pressed() -> void:
	selected.emit(destination_dialogue)
