extends Resource
## A data container used by [HubLocation].
class_name CharacterInteraction

## Contains a [SpriteFrames] resource. Used by an individual [HubLocation]. The 
## passed [SpriteFrames] must contain an animation with an id of [member animation_to_play]
@export var animations : SpriteFrames
@export var animation_to_play : String = "default" ## The name of the animation to play. 
@export var interaction_dialogue : Dialogue ## A [Dialogue] resource to be habilitated by an individual [HubLocation].
@export_group("Advanced Settings")
@export var one_shot : bool = false ## Wheter the the player may interact only once.
@export var marker_offset : Vector2i = Vector2i(0, -32) ## The offset of the exclamation dialogue marker.
@export_enum("Low", "Medium", "High") var priority : int ## How much the player should care about starting this interaction.
