extends CharacterBody2D


# ->> W,A,S,D FOR MOVEMENT J,K FOR DASH AND ATTACK <<-
# ->> W,A,S,D FOR MOVEMENT J,K FOR DASH AND ATTACK <<-
@export var player_projectile_scene: PackedScene

# -------------------------
# MOVEMENT
# -------------------------

var SPEED = 100
var facing_direction = Vector2.DOWN


# -------------------------
# PLAYER STATS
# -------------------------

var health = 100
var stamina = 100

var max_health = health
var max_stamina = stamina

var is_stamina_regen = false
var is_dash_cooldown = false
var is_attack_cooldown = false
var is_heavy_attack_cooldown = false
var is_blocking = false
var is_stunned = false


# -------------------------
# ATTACK STATS
# -------------------------

var base_damage = 20
var heavy_damage = 30
var crit_chance = 0.05
var crit_multiplier = 2.0


# -------------------------
# START
# -------------------------

func _ready():
	$attack_area/attack_collision.disabled = true
	$attack_area/temp_visual.hide()
	$heavy_attack_area/attack_collision.disabled = true
	$heavy_attack_area/temp_visual.hide()

	$UI/health_bar.max_value = max_health
	$UI/health_bar.value = health

	$UI/stamina_bar.max_value = max_stamina
	$UI/stamina_bar.value = stamina


# -------------------------
# MAIN PLAYER LOOP
# -------------------------

func _physics_process(_delta: float) -> void:
	
	if is_stunned:
		velocity = Vector2.ZERO
		return

	var direction = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)


	# DASH
	if Input.is_action_just_pressed("game_a_dash") && !is_dash_cooldown && stamina >= 20:
		$hitbox_area/hitbox_collision.disabled = true

		SPEED = 350

		is_dash_cooldown = true
		is_stamina_regen = false

		$dash_cooldown.start()
		$stamina_regen.start()

		stamina -= 20
		$UI/stamina_bar.value = stamina

		await get_tree().create_timer(0.2).timeout

		SPEED = 100
		$hitbox_area/hitbox_collision.disabled = false


	# ATTACK & BLOCK & SHOOT
	if Input.is_action_just_pressed("game_a_attack") && !is_attack_cooldown && stamina >= 10:
		attack("k")

		is_attack_cooldown = true
		is_stamina_regen = false

		$attack_cooldown.start()
		$stamina_regen.start()

		stamina -= 10
		$UI/stamina_bar.value = stamina
		
		
	if Input.is_action_just_pressed("game_a_heavy_attack") && !is_heavy_attack_cooldown && stamina >= 30:
		attack("l")

		is_heavy_attack_cooldown = true
		is_stamina_regen = false

		$heavy_attack_cooldown.start()
		$stamina_regen.start()

		stamina -= 30
		$UI/stamina_bar.value = stamina
		
		
	if Input.is_action_pressed("game_a_blocking"):
		is_blocking=true
		direction = Vector2.ZERO

	else:
		is_blocking=false
		
	if Input.is_action_just_pressed("game_a_projectile") && !is_attack_cooldown && stamina >= 10:
		shoot()
		is_attack_cooldown = true
		is_stamina_regen = false

		$attack_cooldown.start()
		$stamina_regen.start()

		stamina -= 10
		$UI/stamina_bar.value = stamina


	# MOVEMENT / ANIMATION
	if direction != Vector2.ZERO:
		facing_direction = direction
		direction = direction.normalized()

		update_animation(facing_direction)

	else:
		update_idle(facing_direction)


	velocity = direction * SPEED

	move_and_slide()

	update_attack_area(facing_direction)
	
# -------------------------
# MOVEMENT ANIMATIONS
# -------------------------

func update_animation(direction):

	if direction == Vector2.UP:
		$animations.play("move_up")

	elif direction == Vector2.DOWN:
		$animations.play("move_down")

	elif direction == Vector2.LEFT:
		$animations.play("move_left")

	elif direction == Vector2.RIGHT:
		$animations.play("move_right")

	elif direction == Vector2(1, -1):
		$animations.play("move_up_right")

	elif direction == Vector2(-1, -1):
		$animations.play("move_up_left")

	elif direction == Vector2(1, 1):
		$animations.play("move_down_right")

	elif direction == Vector2(-1, 1):
		$animations.play("move_down_left")


# -------------------------
# IDLE ANIMATIONS
# -------------------------

func update_idle(direction):

	if direction == Vector2.UP:
		$animations.play("idle_up")

	elif direction == Vector2.DOWN:
		$animations.play("idle_down")

	elif direction == Vector2.LEFT:
		$animations.play("idle_left")

	elif direction == Vector2.RIGHT:
		$animations.play("idle_right")

	elif direction == Vector2(1, -1):
		$animations.play("idle_up_right")

	elif direction == Vector2(-1, -1):
		$animations.play("idle_up_left")

	elif direction == Vector2(1, 1):
		$animations.play("idle_down_right")

	elif direction == Vector2(-1, 1):
		$animations.play("idle_down_left")


# -------------------------
# ATTACK AREA DIRECTION
# -------------------------

func update_attack_area(direction):

	if direction == Vector2.UP:
		$attack_area.position = Vector2(0, -20)
		$attack_area.rotation_degrees = 180
		$heavy_attack_area.position = Vector2(0, -20)
		$heavy_attack_area.rotation_degrees = 180

	elif direction == Vector2.DOWN:
		$attack_area.position = Vector2(0, 20)
		$attack_area.rotation_degrees = 0
		$heavy_attack_area.position = Vector2(0, 20)
		$heavy_attack_area.rotation_degrees = 0

	elif direction == Vector2.LEFT:
		$attack_area.position = Vector2(-20, 0)
		$attack_area.rotation_degrees = 90
		$heavy_attack_area.position = Vector2(-20, 0)
		$heavy_attack_area.rotation_degrees = 90

	elif direction == Vector2.RIGHT:
		$attack_area.position = Vector2(20, 0)
		$attack_area.rotation_degrees = -90
		$heavy_attack_area.position = Vector2(20, 0)
		$heavy_attack_area.rotation_degrees = -90

	elif direction == Vector2(1, -1):
		$attack_area.position = Vector2(15, -15)
		$attack_area.rotation_degrees = -135
		$heavy_attack_area.position = Vector2(15, -15)
		$heavy_attack_area.rotation_degrees = -135

	elif direction == Vector2(-1, -1):
		$attack_area.position = Vector2(-15, -15)
		$attack_area.rotation_degrees = 135
		$heavy_attack_area.position = Vector2(-15, -15)
		$heavy_attack_area.rotation_degrees = 135

	elif direction == Vector2(1, 1):
		$attack_area.position = Vector2(15, 15)
		$attack_area.rotation_degrees = -45
		$heavy_attack_area.position = Vector2(15, 15)
		$heavy_attack_area.rotation_degrees = -45

	elif direction == Vector2(-1, 1):
		$attack_area.position = Vector2(-15, 15)
		$attack_area.rotation_degrees = 45
		$heavy_attack_area.position = Vector2(-15, 15)
		$heavy_attack_area.rotation_degrees = 45


# -------------------------
# ATTACK
# -------------------------

func attack(a):
	if a=="k":
		$attack_area/temp_visual.show()
		$attack_area/attack_collision.disabled = false
		await get_tree().create_timer(0.2).timeout
		$attack_area/temp_visual.hide()
		$attack_area/attack_collision.disabled = true
	
	elif a=="l":
		$heavy_attack_area/temp_visual.show()
		$heavy_attack_area/attack_collision.disabled = false
		await get_tree().create_timer(0.2).timeout
		$heavy_attack_area/temp_visual.hide()
		$heavy_attack_area/attack_collision.disabled = true


# -------------------------
# HEALTH
# -------------------------

func heal(amount):

	health += amount
	health = min(health, max_health)

	$UI/health_bar.value = health

# -------------------------
# STAMINA
# -------------------------

func regen_stamina(amount):

	stamina += amount
	stamina = min(stamina, max_stamina)

	$UI/stamina_bar.value = stamina


func take_damage(dmg : int):
	if is_blocking:
		stamina -= dmg
		stamina = max(stamina, 0)
		$UI/stamina_bar.value = stamina

		if stamina <= 0:
			is_blocking = false
			is_stunned = true
			$stun_cooldown.start()
		return

	if dmg >= health:
		health = 0
		#lose logic
	else:
		health -= dmg

	$UI/health_bar.value = health
		
# -------------------------
# COLLISION SIGNALS
# -------------------------

func _on_attack_area_area_entered(area: Area2D) -> void:
	if area.get_parent() == null: return
	var enemy := area.get_parent()
	if enemy is GameAEnemy:
		enemy.take_damage(base_damage)
		
func _on_heavy_attack_area_area_entered(area: Area2D) -> void:
	if area.get_parent() == null: return
	var enemy := area.get_parent()
	if enemy is GameAEnemy:
		enemy.take_damage(heavy_damage)
		
func shoot():
	var projectile: GameAProjectile = player_projectile_scene.instantiate()
	projectile.direction = facing_direction.normalized()
	projectile.speed = 250.0
	projectile.damage = 10
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position + facing_direction.normalized() * 30
	
func _on_hitbox_area_area_entered(area: Area2D) -> void:
	# make sure area its the enemy hitbox
	if area.get_parent() == null: return
	
	var enemy := area.get_parent()
	
	if enemy is GameAEnemy:
		take_damage(enemy.dmg)

func _on_attack_area_body_entered(body: Node2D) -> void:
	pass

func _on_hitbox_area_body_entered(body: Node2D) -> void:
	pass

# -------------------------
# COOLDOWN / REGEN TIMERS
# -------------------------

func _on_dash_cooldown_timeout() -> void:
	is_dash_cooldown = false

func _on_attack_cooldown_timeout() -> void:
	is_attack_cooldown = false

func _on_stamina_regen_timeout() -> void:
	is_stamina_regen = true
	$regen.start()
	
func _on_regen_timeout() -> void:
	if is_stamina_regen:
		regen_stamina(50)

	if stamina >= max_stamina || !is_stamina_regen:
		$regen.stop()


func _on_heavy_attack_cooldown_timeout() -> void:
	is_heavy_attack_cooldown=false




func _on_stun_cooldown_timeout() -> void:
	is_stunned=false;
	$stamina_regen.start()
