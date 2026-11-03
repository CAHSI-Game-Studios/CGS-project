@tool
extends Resource
## A data container utilized by [DialogueSystem].
class_name Dialogue

## Determines how the [DialogueSystem] will interact with this [Dialogue]
enum TYPE {
	LINEAR,
	CHOICE, 
	ENDING
}

## The unique identifier of the dialogue
@export var id : StringName
## Determines how this dialogue advances.
@export var dialogue_type : TYPE = TYPE.LINEAR:
	set(value):
		dialogue_type = value
		notify_property_list_changed()

@export_group("Content")

## Name displayed as the dialogue speaker.
@export var speaker : String

## Dialogue text. Supports BBCode.
@export_multiline var text : String

## Controls the time (in seconds) the entirety of the dialogue takes to display.
@export_range(1.0, 10.0, 1.0) var text_duration : float = 1.0

## Determines when the player is allowed to skip the dialogue. 0.0 means the player 
## may instantly skip the dialogue, 1.0 means the entire dialogue must play out before skipping.
@export_range(0.0,1.0, 0.05) var allow_skip_at : float = 1.0


@export_group("Flow")

## Dialogue displayed after this dialogue.
## Only used by LINEAR dialogues.
@export var next_dialogue : Dialogue

## Available responses and the dialogue each response leads to.
## Only used by CHOICE dialogues.
@export var responses : Dictionary[String, Dialogue] = {}


## Remove inspector options based on DialogueType
func _validate_property(property : Dictionary) -> void:
	match property.name:
		&"next_dialogue":
			if dialogue_type != TYPE.LINEAR:
				property.usage = PROPERTY_USAGE_NO_EDITOR
		&"responses":
			if dialogue_type != TYPE.CHOICE:
				property.usage = PROPERTY_USAGE_NO_EDITOR
