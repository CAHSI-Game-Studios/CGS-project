# author nu-hazd, rev: oct 28, 2026
extends Area2D
## A representation of an interaction area inside the Hub. Uses a [CharacterInteraction] resource
## passed by the [HubManager]
class_name HubLocation

## Emitted upon [method start_interaction] being called. Note that a single [CharacterInteraction]
## may result multiple emissions of this signal.
signal interactionStarted(interactionID : String)

## A reference to the character-to-display's [AnimatedSprite2D]
@onready var character_display: AnimatedSprite2D = $characterDisplay 
## Reference to the interaction exclamation mark [Sprite2D].
@onready var marker : Sprite2D = $characterDisplay/marker 

## A reference to the [DialogueSystem]. Is [code]null[/code] until initialized by [HubManager].
var dialogue_system_reference : DialogueSystem

## A reference to the data obtained upon [HubManager] calling [method.setup_location].
var interaction_data : CharacterInteraction 

var interacted : bool = false ## Whether this HubLocation has called its [method start_interaction].

## By default, do not recieve player input until [method _on_body_entered]
func _ready() -> void:
	set_process_unhandled_input(false)

func _unhandled_input(event: InputEvent) -> void:
	# TODO: Replace with "interact" or similar action.
	if event.is_action("ui_accept") and not event.is_echo():
		if interaction_data.one_shot and interacted:
			return
		# Loosey goosy implementation
		elif dialogue_system_reference.is_processing(): 
			return
		start_interaction()
## Begins an interaction using the current [member interaction_data].
func start_interaction() -> void:
	dialogue_system_reference.set_current_dialogue(interaction_data.interaction_dialogue)
	dialogue_system_reference.open_system()
	marker.hide()
	interacted = true
	interactionStarted.emit(interaction_data.id)

## Initializes a the [HubLocation] given a [CharacterInteraction]. 
## A reference to the [DialogueSystem] is passed and then stored in [member dialogue_system_reference].
func setup_location(data : CharacterInteraction, dialogue_system : DialogueSystem) -> bool:
	if catch_errors(data):
		return false
	interaction_data = data
	character_display.flip_h = interaction_data.flip_h
	character_display.sprite_frames = interaction_data.animations
	character_display.play(interaction_data.animation_to_play)
	marker.region_rect = Rect2 (priority*16, 0 ,16, 16)
	position = interaction_data.sprite_offset
	marker.position = interaction_data.marker_offset
	monitoring = not interaction_data.display_only
	dialogue_system_reference = dialogue_system
	return true

## Restores a [HubLocation] to its disabled state. 
## May be useful for Hub transitions between games, and certain events.
func reset_location() -> void:
	interacted = false
	character_display.stop()
	character_display.sprite_frames = null
	interaction_data = null
	marker.position = Vector2i(0, -32)
	position = Vector2i.ZERO
	marker.hide()
	set_process_unhandled_input(false)
	self.monitoring = false

## Called upon [param body] entering the [HubLocation]'s [CollisionShape2D] while [member monitoring] is
## [code]true[/code]. If the [param body] is the player, it enables the input.
func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D: ## TODO: Replace with "HubPlayer" class or similar.
		set_process_unhandled_input(true)
		if not (interaction_data.one_shot and interacted):
			marker.show()
## Called upon [param body] exiting the [HubLocation]'s [CollisionShape2D] while [member monitoring] is
## [code]true[/code]. If the [param body] is the player, it disables the input and closes the
## [member dialogue_system_reference].
func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D: ## TODO: Replace with "HubPlayer" class or similar.
		set_process_unhandled_input(false)
		marker.hide()
		if dialogue_system_reference.is_processing():
			dialogue_system_reference.close_system()
## Used by [method start_interaction] to determine if the passed [CharacterInteraction] is valid.
## Logs the missing attributes as errors in the "Output" tab.
func catch_errors(data : CharacterInteraction) -> bool:
	var errs : Array[String] = []
	if data == null:
		errs.push_back("Null character interaction beign set")
	if data.animation_to_play == "":
		errs.push_back("Empty animation identifier beign set.")
	if data.animations == null:
		errs.push_back("Null animation identifier beign set.")
	elif not data.animations.has_animation(data.animation_to_play):
		errs.push_back("SpriteFrames resource does not contain: %s " % data.animation_to_play)
	if data.initial_dialogue == null and not data.display_only:
		errs.push_back("Null dialogue resource.")
	if not errs.is_empty():
		push_error("At: %s, %d errors:" % [self.name, errs.size()])
		for err : String in errs:
			push_error(err)
		return false
	return true
