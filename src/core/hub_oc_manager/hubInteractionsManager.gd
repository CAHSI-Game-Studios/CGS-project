class_name HubInteractionsManager extends Node

@export var current_hub_state : HubState
@export var dialogue_system: DialogueSystem 

enum HUB_LOCATION {
	NORTH, SOUTH, EAST, WEST # Temporary locations, to be replaced with actual locations.
}

@export var location_markers : Dictionary[HUB_LOCATION, Marker2D] = {
	HUB_LOCATION.NORTH : null,
	HUB_LOCATION.SOUTH : null,
	HUB_LOCATION.EAST : null,
	HUB_LOCATION.WEST : null
}
func _ready() -> void:
	print(HUB_LOCATION.keys()[location_markers.keys()[0]])


func set_interactions_from_hub_state(hub_state : HubState) -> bool:
	reset_locations()
	if hub_state == null:
		push_warning("Null HubState resource.")
		return false
	current_hub_state = hub_state
	for location : HUB_LOCATION in current_hub_state.interactions:
		set_interaction_at(location, current_hub_state.interactions[location])
	return true

func set_interaction_at(place : HUB_LOCATION, interaction : CharacterInteraction) -> void:
	var interaction_area : InteractionArea = location_markers[place].get_child(0)
	if interaction_area.interaction_data != null:
		interaction_area.reset_location()
	interaction_area.setup_location(interaction, dialogue_system)
func reset_locations() -> void:
	for loc : HUB_LOCATION in location_markers:
		var location : InteractionArea = location_markers[loc].get_child(0)
		location.reset_location()

func check_integrity() -> void:
	if HUB_LOCATION.keys().size() != location_markers.keys().size():
		push_warning(
			"Location enum size: %d, while dictionary keys size: %d." % 
			[HUB_LOCATION.keys().size(), location_markers.keys().size()])
	for key : HUB_LOCATION in location_markers:
		if not location_markers.has(key):
			push_warning("%s is not assigned a Marker2D." % HUB_LOCATION.keys()[key])
		elif location_markers[key].get_child_count() == 0:
			push_warning("At %s, marker does not have a InteractionArea child." % location_markers[key].name)
		elif location_markers[key].get_child_count() == 1:
			if location_markers[key].get_child(0) is not InteractionArea:
				push_warning("At %s, marker child is not InteractionArea." % location_markers[key].name)
			elif location_markers[key].get_child(0).interaction_data != null:
				push_warning("At %s, marker InteractionArea child had data configured before initialization." % location_markers[key].name)
		else:
			push_warning("At %s, marker hase more than one child." % location_markers[key].name)
			
