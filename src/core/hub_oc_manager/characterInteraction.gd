# author: nu-hazd, rev: oct 27, 2026
extends Resource
## A data container used by [HubLocation].
class_name CharacterInteraction

## The unique identifier of this [CharacterInteraction]. Currently used by [signal HubLocation.interactionStarted].
## May be useful for flagging certain [CharacterInteraction]s as complete/seen.
@export var id : StringName 
## The sprite data container used by an individual [HubLocation] upon [member HubLocation.setup_location]. The 
## passed [SpriteFrames] must contain an animation with an id of [member animation_to_play].
@export var animations : SpriteFrames
## The identifier of the desired animation. [member animations] may contain multiple animations.
## Beware of typos, as [method HubLocation.setup_location] will fail if [method SpriteFrames.has_animation] returns [code]false[/code].
@export var animation_to_play : String = "default" 
@export var dialogue : Dialogue ## The [Dialogue] the [DialogueSystem] will display upon [member HubLocation.start_interaction].
@export_group("Advanced Settings")
## Wheter the [HubLocation] limites the player to a single interaction.
@export var one_shot : bool = false 
## If [code]true[/code], the [HubLocation] containing this [CharacterInteraction] will not
## enable [member HubLocation.monitoring] on [method HubLocation.setup_location].
@export var display_only : bool = false
## Whether the [member HubLocation.character_display] is flipped horizontally. Useful for making sprites
## that face right look like they are facing left.
@export var flip_h : bool = false
## The offset of [member HubLocation.character_display] will have upon being initialized. Useful for variations within the same [HubLocation].
## Note that the [HubLocation]s [Area2D] will also be offset by this value.
@export var sprite_offset : Vector2i = Vector2i.ZERO
## The offset [member HubLocation.marker] will have upon being initialized.
## Note this offset is relative to [member sprite_offset].
@export var marker_offset : Vector2i = Vector2i(0, -32) 
## Currently unused besides altering the displayed frane of [member HubLocation.marker] sprite sheet.
## May be useful if we every wish to heapify [CharacterInteraction]s. 
@export_enum("Low", "Medium", "High") var priority : int = 0 # 0 means "Low", 1 "Medium", 2 "High" and vice-versa

## Enables contruction of a this resource via the CharacterInteraction.new(args) method.
func _init(
	identifier : StringName, 
	anims : SpriteFrames,
	dia : Dialogue, 
	anim_to_play : String,
	o_shot : bool = false, disp_only : bool = false,
	s_offset : Vector2i = Vector2i.ZERO, m_offset : Vector2i = Vector2i(0, -32),
	prio : int = 0
	) -> void:
	self.id = identifier
	self.animations = anims
	self.dialogue = dia
	self.animation_to_play = anim_to_play
	self.one_shot = o_shot
	self.display_only = disp_only
	self.sprite_offset = s_offset
	self.marker_offset = m_offset
	self.priority = prio
	
