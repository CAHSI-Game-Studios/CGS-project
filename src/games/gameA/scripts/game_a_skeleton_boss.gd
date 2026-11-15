extends GameABoss

# ---------------- Arrow Attack -------------------
@export var arrow_scene: PackedScene
@export var arrow_speed: float = 250.0
@export var arrow_damage: int = 10
@export var arrow_count: int = 3
@export var arrow_spread: float = 45.0

#-----------------------------------------------------

func _ready() -> void:
	super()
	add_attack(attack_triple_shot,   50,  400)

# ---------------- Arrow Attack -------------------
func attack_triple_shot() -> void:
	modulate = Color(1.0, 0.5, 0.5)
	await wait(windup_time)
	modulate = Color.WHITE
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

#-----------------------------------------------------
