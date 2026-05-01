extends Area2D

func _on_body_entered(body: Node2D) -> void:
	# Verificamos si es el Chef quien nos tocó
	if body.name == "Chef":
		# Le avisamos al Chef que ahora tiene el carrito
		if body.has_method("equipar_carrito"):
			body.equipar_carrito()
			
		# El ítem desaparece del suelo porque ya lo recolectamos
		queue_free()
