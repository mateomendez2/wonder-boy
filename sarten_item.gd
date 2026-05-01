extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name.to_lower() == "chef":
		# Si el Chef lo toca, llamamos a su nueva función y borramos este ítem
		if body.has_method("equipar_sarten"):
			body.equipar_sarten()
			queue_free()
