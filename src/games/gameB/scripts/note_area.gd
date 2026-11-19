extends Area2D
signal despawned

func kill():
	despawned.emit()
	get_parent().queue_free()
