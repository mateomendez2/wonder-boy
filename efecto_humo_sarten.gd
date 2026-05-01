extends Node2D

func _ready() -> void:
	# 1. EMPIEZA MÁS PEQUEÑO: 
	# Lo bajamos a la mitad (0.5) para que no sea un manchón gigante
	scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	
	# 2. SE DESVANECE MÁS RÁPIDO: 
	# Bajamos el tiempo de 0.5 a 0.2 o 0.3 segundos.
	# También bajamos el tamaño final para que no crezca tanto.
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	
	await tween.finished
	queue_free()
