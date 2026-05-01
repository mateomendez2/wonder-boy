extends CanvasLayer

func _ready() -> void:
	# 1. Le damos un microsegundo a la cámara para que se acomode en el Chef
	await get_tree().process_frame
	
	# 2. Pausamos el juego para que no te ataquen los enemigos
	get_tree().paused = true
	
	# 3. Nos aseguramos de que el telón negro se vea al 100%
	$TelonNegro.modulate.a = 1.0 
	
	# 4. Esperamos 2 segundos para que el jugador lea "Area 2"
	await get_tree().create_timer(2.0, true, false, true).timeout
	
	# 5. EFECTO FADE OUT: Desvanecemos el telón negro (que se lleva la imagen con él)
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property($TelonNegro, "modulate:a", 0.0, 1.0) # Tarda 1 segundo en desaparecer
	await tween.finished 
	
	# 6. Despausamos el juego y borramos esta intro
	get_tree().paused = false
	queue_free()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
