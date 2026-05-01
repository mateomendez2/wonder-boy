extends Sprite2D

func _ready() -> void:
	# Creamos el animador
	var tween = create_tween()
	
	# Le decimos que mueva el cartelito 40 píxeles hacia arriba en 0.8 segundos
	tween.tween_property(self, "global_position", global_position - Vector2(0, 30), 1.2)
	
	# En paralelo (al mismo tiempo), le decimos que se vuelva transparente (modulate:a)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.2)
	
	# Cuando termina la animación de 0.8 segundos, el cartelito se borra solo de la memoria
	tween.tween_callback(queue_free)
