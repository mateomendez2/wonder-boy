extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		var camara = body.get_node("Camera2D")
		
		# Calculamos el alto (dividido por el zoom, por si la cámara está acercada)
		var alto_pantalla = get_viewport_rect().size.y / camara.zoom.y
		var centro_y = camara.get_screen_center_position().y
		
		# CONGELAMIENTO PERFECTO: 
		# Usamos round() para no perder decimales y le damos 1 pixel de margen extra
		camara.limit_top = int(round(centro_y - (alto_pantalla / 2.0))) - 1
		camara.limit_bottom = int(round(centro_y + (alto_pantalla / 2.0))) + 1

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Chef":
		var camara = body.get_node("Camera2D")
		
		# Usamos tu cruz Marker2D para saber hasta dónde estirar el piso
		var altura_salida = int($PuntoSalida.global_position.y)
		
		# Hacemos la transición súper rápida (0.2s) para que siga al súper salto
		var tween_camara = create_tween().set_parallel(true)
		tween_camara.tween_property(camara, "limit_bottom", altura_salida, 0.2).set_trans(Tween.TRANS_SINE)
		
		# Le abrimos el techo hacia el infinito para que pueda volar
		tween_camara.tween_property(camara, "limit_top", -10000000, 0.2)
