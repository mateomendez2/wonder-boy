extends Sprite2D

func _ready() -> void:
	# Creamos una animación rápida de medio segundo (0.5) para que se vuelva invisible
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Cuando termina la animación, el humo se borra del juego automáticamente
	tween.tween_callback(queue_free)
