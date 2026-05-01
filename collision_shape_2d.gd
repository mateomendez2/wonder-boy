extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# Buscamos la cámara del Chef
		var camara = body.get_node("Camera2D")
		
		# Calculamos el alto de tu ventana y el centro actual
		var alto_pantalla = get_viewport_rect().size.y
		var centro_y = camara.get_screen_center_position().y
		
		# MAGIA: Le ponemos "paredes" invisibles arriba y abajo a la cámara 
		# para que quede atrapada exactamente en el cuadro actual
		camara.limit_top = int(centro_y - (alto_pantalla / 2.0))
		camara.limit_bottom = int(centro_y + (alto_pantalla / 2.0))


func _on_body_exited(body: Node2D) -> void:
	if body.name == "Chef":
		var camara = body.get_node("Camera2D")
		
		# Cuando el Chef se va de la zona, rompemos las paredes
		# y le devolvemos a la cámara sus valores infinitos por defecto
		camara.limit_top = -10000000
		camara.limit_bottom = 10000000 
