extends Area2D

# Acá vas a poner el nombre de tu escena de resultados finales
@export var escena_siguiente: String = "res://pantalla_bonus.tscn" 

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# --- LIMPIEZA DE AUDIO TOTAL ---
		
		# 1. Buscamos la música del nivel y la frenamos
		var musica_nivel = get_tree().current_scene.get_node_or_null("MusicaFondo")
		if musica_nivel:
			musica_nivel.stop()
		
		# 2. NUEVO: Frenamos el sonido de la sartén por si llega con ella
		# Accedemos al nodo SonidoCarrito que está dentro del Chef
		if body.has_node("SonidoCarrito"):
			body.get_node("SonidoCarrito").stop()
		
		# 3. Le pedimos al GameManager que arranque la música de victoria
		GameManager.reproducir_musica_victoria()
		# -------------------------------

		body.nivel_terminado = true
		
		# (El resto de tu código de cámara y timer...)
		var camara = body.get_node("Camera2D")
		var ancho_pantalla = get_viewport_rect().size.x / camara.zoom.x
		var centro_x = camara.get_screen_center_position().x
		camara.limit_left = int(round(centro_x - (ancho_pantalla / 2.0)))
		camara.limit_right = int(round(centro_x + (ancho_pantalla / 2.0)))
		
		await get_tree().create_timer(3.0).timeout
		
		GameManager.nivel_superado = true
		get_tree().change_scene_to_file(escena_siguiente)
