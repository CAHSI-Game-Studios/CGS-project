extends GameAProjectile

func _on_area_entered(area: Area2D):
	if area.get_parent() == null:
		return

	var enemy := area.get_parent()

	if enemy is GameAEnemy:
		enemy.take_damage(damage)

	queue_free()
	
func _on_body_entered(body: Node2D):
	if body is GameAEnemy:
		body.take_damage(damage)

	queue_free()
