class_name GameAProjectileEnemy
extends GameAEnemy

enum State { CHASE, WINDUP, COOLDOWN }

@export var projectile_scene: PackedScene

@export var attack_distance : float = 120.0
@export var windup_time : float = 0.8
@export var projectile_speed : float = 250.0
@export var cooldown_time : float = 1.0


var state : State = State.CHASE
var state_timer : float = 0.0

## ------- SPRITE ----------------

enum Biome {FOREST, DESERT, CASTLE}

const SPRITES_FOLDER := "res://games/gameA/assets/"

## ------- SPRITE ----------------
@export var biome: Biome = Biome.FOREST
@export var sprite_name: String = "enemy"
@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")

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

func play_animation(animation : String) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	if sprite.sprite_frames.has_animation(animation):
		sprite.play(animation)

func update_behavior(delta: float) -> void:
	match state:
		State.CHASE:
			if distance_to_target() <= attack_distance and has_line_of_sight(target):
				start_windup()
			else:
				super(delta)
		State.WINDUP:
			stop_moving()
			state_timer -= delta
			if state_timer <= 0.0:
				shoot()
				start_cooldown()
		State.COOLDOWN:
			stop_moving()
			state_timer-= delta
			if state_timer<=0.0:
				can_chase = true
				state = State.CHASE

func start_windup():
	state = State.WINDUP
	state_timer = windup_time
	can_chase = false

func shoot():
	var projectile: GameAProjectile = projectile_scene.instantiate()
	set_up_projectile(projectile)
	## add the projectile scene to the ACTUALLY game, not this enemy
	get_parent().add_child(projectile)
	## projectile position its the enemy position
	projectile.global_position = global_position

func start_cooldown():
	state = State.COOLDOWN
	state_timer = cooldown_time

func set_up_projectile(projectile : GameAProjectile)->void:
	projectile.direction = global_position.direction_to(player.global_position)
	projectile.speed = projectile_speed
	projectile.damage = dmg
	
	
	
