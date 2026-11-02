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


func _ready() -> void:
	hitbox.monitoring = false
	hitbox.body_entered.connect(_on_hitbox_body_entered)

func update_behavior(delta: float) -> void:
	match state:
		State.CHASE:
			if distance_to_player() <= attack_distance and has_line_of_sight(player):
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
	dash_target = player.global_position
	dash_direction = global_position.direction_to(dash_target)
	# active hitbox detection
	hitbox.set_deferred("monitoring", true)


func start_cooldown() -> void:
	state = State.COOLDOWN
	state_timer = cooldown_time
	hitbox.set_deferred("monitoring", false)


func _on_hitbox_body_entered(body: Node2D) -> void:
	if body == player:
		hitbox.set_deferred("monitoring", false) 
