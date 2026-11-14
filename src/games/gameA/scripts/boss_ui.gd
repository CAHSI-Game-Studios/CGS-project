extends CanvasLayer

var health_bar : ProgressBar = null
@onready var boss_name_label: Label = $BossName
@onready var damage_bar : ProgressBar = $DamageBar

@export var damage_bar_delay : float = 1.0
@export var damage_bar_duration : float = 1.0

var damage_tween: Tween


func _ready() -> void:
	# reminder : the ready of the childs run first (didnt know that lmao)
	await get_parent().ready
	health_bar = get_parent().health_bar
	damage_bar.max_value = health_bar.max_value
	damage_bar.value = health_bar.value
	setup_label_name()
	
	health_bar.value_changed.connect(_on_health_bar_changed)
	

## ------------- UI -----------------
func setup_label_name():
	boss_name_label.text = get_parent().name
	
func _on_health_bar_changed(new_value : float) -> void:
	if damage_tween:
		damage_tween.kill()
	
	damage_tween = create_tween()
	damage_tween.tween_interval(damage_bar_delay)
	damage_tween.tween_property(damage_bar, "value", new_value, damage_bar_duration)
