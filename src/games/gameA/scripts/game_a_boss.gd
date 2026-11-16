class_name GameABoss
extends GameAEnemy

signal boss_defeated

class BossAttack:
	var action : Callable
	var min_range : float
	var max_range : float
	var weight : float
	
	func _init(_action : Callable, _min_range : float, _max_range : float, _weight : float):
		self.action = _action
		self.min_range = _min_range
		self.max_range = _max_range
		self.weight = _weight

enum State { MOVE, ATTACK ,COOLDOWN , DEAD}

#@export var boss_name : String = "Boss"
@export var windup_time: float = 0.8
@export var recovery_time : float = 0.8
@export var attack_cooldown : float = 1.5
@export var cooldown_randomness : float = 0.5
@export var death_delay : float = 1.5

var state : State = State.MOVE

var attacks : Array[BossAttack] = []
var last_attack : BossAttack
var cooldown_timer : float = 0.0
var recovery_timer : float = 0.0

func add_attack(action, min_range, max_range, weight : float = 1.0):
	var attack : BossAttack = BossAttack.new(action, min_range, max_range, weight)
	attacks.append(attack)

func update_behavior(delta : float) -> void:
	match state:
		State.MOVE:
			cooldown_timer -= delta
			if cooldown_timer <= 0.0:
				var attack : BossAttack = choose_attack()
				if attack:
					start_attack(attack)
					return
			# not attack avaible yet
			move_between_attacks(delta)
		
		State.COOLDOWN:
			stop_moving()
			recovery_timer -= delta
			if recovery_timer <= 0.0:
				state = State.MOVE
				can_chase = true
				cooldown_timer = attack_cooldown + randf_range(-cooldown_randomness, cooldown_randomness)
		
		_:
			pass
				
# how the boss moves while waiting for its next attack.
# by default it chases the player. child bosses override this
# to move differently.
func move_between_attacks(_delta : float)->void:
	chase_target(player)

func choose_attack() -> BossAttack:
	var distance = distance_to_player()
	
	var valid_attacks : Array[BossAttack] = []
	# add attakcs with valid range
	for attack in attacks:
		if distance >= attack.min_range and distance <= attack.max_range:
			valid_attacks.append(attack)
	
	# this will erase the last attack so it doesnt repeat. (for now, idk if this is a good desicion)
	if valid_attacks.size() > 1:
		valid_attacks.erase(last_attack)
	# there is no valid attack
	if valid_attacks.is_empty():
		return null
	
	
	# logic for selecting a random attack, weighted 
	# (higher weight means a higher probability)
	var total := 0.0
	for attack in valid_attacks:
		total += attack.weight
	var roll := randf() * total
	for attack in valid_attacks:
		roll -= attack.weight
		if roll <= 0.0:
			return attack
	return valid_attacks.back()

func start_attack(attack : BossAttack) -> void:
	state = State.ATTACK
	last_attack = attack
	can_chase = false
	stop_moving()
	
	await attack.action.call()
	
	if is_dead():
		return
		
	state = State.COOLDOWN
	recovery_timer = recovery_time


func take_damage(amount : int) -> void:
	if is_dead():
		return
	# the parent class (GameAEnemy) handle the take_damage func.
	super(amount)

# TODO 
func check_phase():
	pass

func die() -> void:
	state = State.DEAD
	can_chase = false
	stop_moving()
	# debug
	modulate = Color.WHITE
	hitbox.set_deferred("monitorable", false)
	boss_defeated.emit()
	
	await wait(death_delay)
	queue_free()

func wait(seconds : float) -> void:
	await get_tree().create_timer(seconds, false).timeout

func is_dead() -> bool:
	return state == State.DEAD

func get_health_bar() -> ProgressBar:
	return $BossUI/DamageBar/HealthBar
