class_name GameAAlly
extends GameACharacter

enum State { FOLLOW, ENGAGE, RETURN, ATTACK }

@export var player: CharacterBody2D

# ------- FOLLOW ----------------
@export var follow_distance: float = 60.0
# only enemies within this distance of the PLAYER are considered targets
@export var leash_radius: float = 300.0
# if the ally gets this far from the player, it drops its target and returns
@export var return_distance: float = 400.0

# ------- TARGETING ----------------
@export var retarget_interval: float = 0.5
# higher -> prefers enemies that are close to the player (more protective)
@export var player_threat_weight: float = 1.0

## ------- ATTACK ----------------
@export var attack_damage: int = 20
@export var attack_range: float = 30
@export var attack_windup: float = 0.3
@export var attack_cooldown: float = 0.8
@export var attack_offset: float = 24.0

@onready var attack_area: Area2D = $AttackArea
@onready var hitbox: Area2D = $Hitbox


var state: State = State.FOLLOW
var target: GameAEnemy
var retarget_timer: float = 0.0
var attack_cooldown_timer: float = 0.0

var is_downed = false

#-------- SPRITES -----------
func update_animation() -> void:
	if sprite == null:
		return

	if velocity.length() < 5.0:
		play_animation("idle")
		return

	if velocity.y < 0 and abs(velocity.y) > abs(velocity.x):
		play_animation("walk_back")
	else:
		play_animation("walk_front")

	if abs(velocity.x) > 5.0:
		sprite.flip_h = velocity.x > 0
	
func _ready() -> void:
	super()
	add_to_group("allies")
	attack_area.monitoring = false

func can_act() -> bool:
	return player != null and player is GameAPlayer and not is_downed

func die() -> void:
	is_downed = true
	target = null
	state = State.FOLLOW
	knockback_velocity = Vector2.ZERO
	stop_moving()
	hitbox.set_deferred("monitorable", false)
	attack_area.set_deferred("monitoring", false)
	modulate = Color(0.5, 0.5, 0.5)

func revive(revive_health: int) -> void:
	is_downed = false
	health = revive_health
	if health_bar:
		hitbox.set_deferred("monitorable", true)
	modulate = Color.WHITE

func is_dead():
	return is_downed
	
func update_behavior(delta: float)-> void:
	attack_cooldown_timer -= delta

	retarget_timer -= delta
	if retarget_timer <= 0.0:
		retarget_timer = retarget_interval
		update_target()

	match state:
		State.FOLLOW:
			if target:
				state = State.ENGAGE
			else:
				follow_player()

		State.ENGAGE:
			# the target can die or leave the leash at any time
			if not is_valid_target(target):
				target = null
				state = State.FOLLOW
				return
			if distance_to_player() > return_distance:
				target = null
				state = State.RETURN
				return
			engage_target()

		State.RETURN:
			# ignores enemies until it is back close to the player
			move_towards_point(player.global_position, SPEED)
			if distance_to_player() <= leash_radius * 0.5:
				state = State.FOLLOW

		State.ATTACK:
			# controlled by start_attack() through its awaits
			pass
	update_animation()

# ------- FOLLOW ----------------
func follow_player() -> void:
	if distance_to_player() > follow_distance:
		move_towards_point(player.global_position, SPEED)
	else:
		stop_moving()

func distance_to_player() -> float:
	return global_position.distance_to(player.global_position)

# ------- TARGETING ----------------
func update_target() -> void:
	if state == State.RETURN or state == State.ATTACK:
		return

	var best: GameAEnemy = null
	var best_score := INF
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as GameAEnemy
		if not is_valid_target(enemy):
			continue
		var score := get_target_score(enemy)
		if score < best_score:
			best_score = score
			best = enemy

	# keep the current target unless the new one is better
	if is_valid_target(target) and best != target:
		if best_score > get_target_score(target):
			return

	target = best

# lower score means better target
func get_target_score(enemy: GameAEnemy) -> float:
	var distance_to_ally := global_position.distance_to(enemy.global_position)
	var distance_to_player_from_enemy := player.global_position.distance_to(enemy.global_position)
	return distance_to_ally + distance_to_player_from_enemy * player_threat_weight

func is_valid_target(enemy) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		return false
	if enemy.has_method("is_dead") and enemy.is_dead():
		return false
	return enemy.global_position.distance_to(player.global_position) <= leash_radius

# ------- ATTACK ----------------
func engage_target() -> void:
	var distance := global_position.distance_to(target.global_position)
	if distance > attack_range:
		move_towards_point(target.global_position, SPEED)
	elif attack_cooldown_timer <= 0.0:
		start_attack()
	else:
		stop_moving()

func start_attack() -> void:
	state = State.ATTACK
	stop_moving()

	# place the attack area in front of the ally, facing the target
	var direction := global_position.direction_to(target.global_position)
	attack_area.position = direction * attack_offset
	attack_area.rotation = direction.angle()

	await get_tree().create_timer(attack_windup, false).timeout

	attack_area.monitoring = true
	await get_tree().physics_frame
	await get_tree().physics_frame

	# hit each enemy inside the area once
	for area in attack_area.get_overlapping_areas():
		var enemy := area.get_parent() as GameAEnemy
		if enemy:
			enemy.take_damage(attack_damage, enemy.global_position - global_position)

	attack_area.monitoring = false
	attack_cooldown_timer = attack_cooldown
	state = State.ENGAGE if is_valid_target(target) else State.FOLLOW
