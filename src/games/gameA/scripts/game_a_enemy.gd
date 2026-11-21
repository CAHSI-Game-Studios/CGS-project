class_name GameAEnemy
extends GameACharacter

@onready var hitbox: Area2D = $Hitbox
@export var player: CharacterBody2D
@export var dmg : int = 20


# ------- TARGETING ----------------
@export var retarget_interval: float = 0.5
# multiplies the distance to allies: >1 prefers the player, <1 prefers allies
@export var ally_priority: float = 1.0

var target: CharacterBody2D
var retarget_timer: float = 0.0


func _ready() -> void:
	super()
	add_to_group("enemies")
	target = player

## ------- SPRITE ----------------

#the childs will handle this
func update_animation() -> void:
	pass

func play_animation(animation : String) -> void:
	pass
		
func _physics_process(delta: float) -> void:
	update_target(delta)
	super(delta)
	update_animation()

func can_act() -> bool:
	return is_valid_target(target)

## the childs will override this function
func update_behavior(_delta: float) -> void:
	# chase target
	chase_target(target)

# ------- TARGETING ----------------
func update_target(delta: float) -> void:
	retarget_timer -= delta
	# retarget right away if the current target is gone
	if retarget_timer > 0.0 and is_valid_target(target):
		return
	retarget_timer = retarget_interval

	var best: Node2D = null
	var best_score := INF
	for candidate in get_possible_targets():
		if not is_valid_target(candidate):
			continue
		var score := get_target_score(candidate)
		if score < best_score:
			best_score = score
			best = candidate

	# keep the current target unless the new one is clearly better
	if is_valid_target(target) and best != target:
		if best_score > get_target_score(target) :
			return

	target = best

func get_possible_targets() -> Array:
	var candidates: Array = []
	if player:
		candidates.append(player)
	candidates.append_array(get_tree().get_nodes_in_group("allies"))
	return candidates

# lower score means better target
func get_target_score(candidate: Node2D) -> float:
	var distance := global_position.distance_to(candidate.global_position)
	if candidate.is_in_group("allies"):
		distance *= ally_priority
	return distance

func is_valid_target(candidate) -> bool:
	if candidate == null or not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
		return false
	if candidate.has_method("is_dead") and candidate.is_dead():
		return false
	return true

#------- CHASE BEHAVIOR ----------------
func chase_target(chase : Node2D) -> void:
	if can_chase:
		move_towards_point(chase.global_position, SPEED)
		
func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)
