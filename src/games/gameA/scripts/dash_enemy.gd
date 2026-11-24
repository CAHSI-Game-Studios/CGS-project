class_name GameADashEnemy
extends GameAEnemy

enum State { CHASE, WINDUP, DASH, COOLDOWN }

# distance to attack
@export var attack_distance: float = 80.0
# before the attack
@export var windup_time: float = 0.4
@export var dash_speed: float = 250.0
@export var dash_max_time: float = 0.35
# after the dash
@export var cooldown_time: float = 0.8
@export var damage: int = 1
# debug purpose
@export var windup_color: Color = Color(1.0, 0.5, 0.5)

var state: State = State.CHASE
var state_timer: float = 0.0
var dash_target: Vector2
var dash_direction: Vector2

## ------- SPRITE ----------------

enum Biome {FOREST, DESERT, CASTLE}

const SPRITES_FOLDER := "res://games/gameA/assets/"

## ------- SPRITE ----------------
@export var biome: Biome = Biome.FOREST
@export var sprite_name: String = "enemy"

func _ready() -> void:
	super()
	apply_biome_sprite()

func apply_biome_sprite() -> void:
	if sprite == null:
		return
	var biome_name: String = Biome.keys()[biome].to_lower()
	var path := SPRITES_FOLDER + sprite_name + "_" + biome_name + ".tres"
	if ResourceLoader.exists(path):
		sprite.sprite_frames = load(path)

func update_animation() -> void:
	if sprite == null:
		return

	if velocity.length() < 5.0:
		play_animation("idle")
		return

	if abs(velocity.x) > abs(velocity.y):
		play_animation("walk_left")
		sprite.flip_h = velocity.x > 0
	elif velocity.y > 0:
		play_animation("walk_front")
		sprite.flip_h = false
	else:
		play_animation("walk_back")
		sprite.flip_h = false

func update_behavior(delta: float) -> void:
	match state:
		State.CHASE:
			if distance_to_target() <= attack_distance and has_line_of_sight(target):
				start_windup()
			else:
				## see GameAEnemy class
				super(delta)
		State.WINDUP:
			stop_moving()
			state_timer -= delta
			# wait for the timer
			if state_timer <= 0.0:
				start_dash()
		State.DASH:
			knockback_velocity = Vector2.ZERO
			state_timer -= delta
			velocity = dash_direction * dash_speed
			move_and_slide()
			var reached := global_position.distance_to(dash_target) <= dash_speed * delta
			## if the enemys movement reached the position, or
			## the hitbox (Area2D) came into contact with the player's body, or
			## the timer stopped
			if reached or get_slide_collision_count() > 0 or state_timer <= 0.0:
				start_cooldown()
		State.COOLDOWN:
			stop_moving()
			state_timer -= delta
			if state_timer <= 0.0:
				state = State.CHASE
				can_chase = true

func start_windup() -> void:
	state = State.WINDUP
	state_timer = windup_time
	can_chase = false
	# debug
	modulate = windup_color

func start_dash() -> void:
	state = State.DASH
	state_timer = dash_max_time
	# debug
	modulate = Color.WHITE
	dash_target = target.global_position
	dash_direction = global_position.direction_to(dash_target)


func start_cooldown() -> void:
	state = State.COOLDOWN
	state_timer = cooldown_time
