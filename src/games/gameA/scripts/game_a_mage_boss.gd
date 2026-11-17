extends GameABoss

# -------------------Move Behavior ----------------
@export var preferred_min_distance : float = 50
@export var preferred_max_distance : float = 100

enum MoveMode { STRAFE, CHASE, RETREAT }
@export var distance_margin : float = 40.0

var move_mode : MoveMode = MoveMode.STRAFE
@export var retreat_speed : float = 30
@export var strafe_speed : float = 30

@export var strafe_switch_min : float = 1.5
@export var strafe_switch_max : float = 3.5

var strafe_direction : int = 1
var strafe_timer : float = 0.0

# ------------- Arrow Attack Variables-------------------
@export var arrow_scene: PackedScene
var arrow_speed: float = 250.0
@export var arrow_damage: int = 10
var arrow_count: int = 3
var arrow_spread: float = 45.0

#-----------------Shockwave Attack------------------------------------
@export var shockwave_scene : PackedScene
@export var shockwave_damage: int = 15

#----------------Horming Orb Attack----------------------------------------------
@export var orb_scene : PackedScene
@export var orb_speed : float = 120.0
@export var orb_damage : int = 20

func _ready() -> void:
	super()
	add_attack(attack_triple_shot, 50, 400)
	add_attack(attack_shockwave, 30, 50)
	add_attack(attack_homing_orb, 50, 400)

##TODO
func move_between_attacks(delta : float) -> void:
	var distance = distance_to_player()
	match move_mode:
		MoveMode.CHASE:
			if distance <= preferred_max_distance - distance_margin:
				move_mode = MoveMode.STRAFE
		MoveMode.RETREAT:
			if distance >= preferred_min_distance + distance_margin:
				move_mode = MoveMode.STRAFE
		MoveMode.STRAFE:
			if distance > preferred_max_distance:
				move_mode = MoveMode.CHASE
			elif distance < preferred_min_distance:
				move_mode = MoveMode.RETREAT

	match move_mode:
		MoveMode.CHASE:
			chase_target(player)
		MoveMode.RETREAT:
			retreat()
		MoveMode.STRAFE:
			strafe(delta)

func retreat():
	var away := player.global_position.direction_to(global_position)
	move_towards_point(global_position + away * 100, retreat_speed)
	
func strafe(delta : float) -> void:
	strafe_timer -= delta
	if strafe_timer <= 0.0 or get_slide_collision_count() > 0:
		strafe_direction *= -1
		strafe_timer = randf_range(strafe_switch_min, strafe_switch_max)
	
	var direction_to_player = global_position.direction_to(player.global_position)
	var side = direction_to_player.orthogonal() * strafe_direction
	move_towards_point(global_position + side * 50.0, strafe_speed)



# ---------------- Arrow Attack -------------------
func attack_triple_shot() -> void:
	await prepare_attack()
	if is_dead():
		return

	var direction := global_position.direction_to(player.global_position)
	shoot_spread(direction, arrow_count, arrow_spread)


func shoot_spread(base_direction: Vector2, count: int, spread_degrees: float) -> void:
	var start_angle: float = -spread_degrees * (count - 1) / 2.0
	for i in count:
		var angle := deg_to_rad(start_angle + spread_degrees * i)
		spawn_arrow(base_direction.rotated(angle))


func spawn_arrow(direction: Vector2) -> void:
	var arrow: GameAProjectile = arrow_scene.instantiate()
	arrow.direction = direction
	arrow.speed = arrow_speed
	arrow.damage = arrow_damage
	get_parent().add_child(arrow)
	arrow.global_position = global_position

#-------------------Shockwave Attack---------------------------------

func attack_shockwave() -> void:
	await prepare_attack()
	if is_dead():
		return
	
	var wave: GameAShockwave = shockwave_scene.instantiate()
	wave.damage = shockwave_damage
	get_parent().add_child(wave)
	wave.global_position = global_position
	
	await wait(0.5)

#------------------------ Horming Orb Attack-------------------------------

func attack_homing_orb()-> void:
	await prepare_attack()
	if is_dead():
		return
	
	var orb : GameAProjectile = orb_scene.instantiate()
	orb.direction = global_position.direction_to(player.global_position)
	orb.speed = orb_speed
	orb.damage = orb_damage
	orb.target = player
	get_parent().add_child(orb)
	orb.global_position = global_position
	
	await wait(0.3)

#--------------------------------------------------------------------
func prepare_attack():
	modulate = Color(1.0, 0.5, 0.5)
	await wait(windup_time)
	modulate = Color.WHITE
