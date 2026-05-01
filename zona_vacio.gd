extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# En vez de hacerle daño normal, le mandamos una orden de muerte fulminante
		if body.has_method("morir_por_caida"):
			body.morir_por_caida()
