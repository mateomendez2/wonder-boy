extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		body.rampa_actual = self # Le prestamos la rampa al Chef

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Chef":
		body.rampa_actual = null # Se la sacamos cuando sale
