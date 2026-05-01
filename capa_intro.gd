extends CanvasLayer

func _ready() -> void:
	# 1. Esperamos una fracción de segundo para que la cámara llegue al Chef
	await get_tree().process_frame
	
	# 2. Ahora sí, congelamos el juego
	get_tree().paused = true
	
	# 3. Nos aseguramos de que el cartel se vea al 100%
	$CartelArea.modulate.a = 1.0 
	
	# 4. Esperamos 1.5 segundos
	await get_tree().create_timer(1.5, true, false, true).timeout
	
	# 5. EFECTO DE DESVANECIMIENTO (Fade Out)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($CartelArea, "modulate:a", 0.0, 1.0) 
	await tween.finished 
	
	# 6. Despausamos el juego y borramos este nodo
	get_tree().paused = false
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
