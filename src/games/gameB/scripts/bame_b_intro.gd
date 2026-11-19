extends Node2D

#Doppio dialogue expressions:
# 0 = Sad, 1 = Mad, 2 = Happy, 3 = Surprised
var cutscene_start = false
@export var line: Dialogue
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween2: Tween = create_tween()
	tween2.tween_property($Fade_in/ColorRect, "modulate:a",0.0,2).from(2.0)
	await tween2.finished
	cutscene_start = true
	$Doppio/AnimationPlayer.play("idle")
	$Bernie/AnimationPlayer.play("idle")
	$DialogueSystem.open_system()
	$DialogueSystem.set_current_dialogue(line)
	
func _process(delta: float) -> void:

		
	if $DialogueSystem.get_current_dialogue() == null and cutscene_start:
		cutscene_start = false
		var tween: Tween = create_tween()
		tween.tween_property($Fade_in/ColorRect, "modulate:a",1.0,2).from(0.0)
		await tween.finished
		$DialogueSystem.open_system()
		await get_tree().create_timer(1).timeout
		get_tree().change_scene_to_file("res://games/gameB/scenes/GameBScene.tscn")
