extends Resource
class_name Dialogue

@export var speaker : String
@export_multiline("Supports BBCode.") var text : String
@export_range(1, 5, 1) var textSpeed : float = 1.0
@export var allowSkipAt : float = 1.0
