class_name GameAShockwave
extends Area2D

@export var max_radius: float = 140.0
@export var duration: float = 0.5

# the enemy will overwrite this 
var damage: int = 0

var hit_targets: Array = []

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var shape: CircleShape2D


func _ready() -> void:
	# copy of the circle shape
	shape = collision.shape.duplicate()
	collision.shape = shape
	set_radius(0.0)

	fit_sprite_to_radius()
	sprite.play()
	sprite.animation_finished.connect(queue_free)

	area_entered.connect(_on_area_entered)
	
	# grow the damage area, then turn it off while the animation finishes
	var tween := create_tween()
	tween.tween_method(set_radius, 0.0, max_radius, duration)
	tween.tween_callback(collision.set_deferred.bind("disabled", true))


func set_radius(value: float) -> void:
	shape.radius = max(value, 0.1)


# scale the sprite once so its full size covers max_radius
func fit_sprite_to_radius() -> void:
	var frame := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	var sprite_base_radius := frame.get_size().x / 2.0
	sprite.scale = Vector2.ONE * (max_radius / sprite_base_radius)


func _on_area_entered(area: Area2D) -> void:
	var target := area.get_parent()
	if target is not GameAPlayer and target is not GameAAlly:
		return
	# a target can re-enter if its hurtbox turns off and on (dash), only hit once
	if target in hit_targets:
		return

	hit_targets.append(target)
	target.take_damage(damage)
