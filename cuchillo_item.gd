extends Area2D

@export var item_a_soltar: PackedScene

func _on_body_entered(body: Node2D) -> void:
	if body.name.to_lower() == "chef":
		# 1. Le avisamos al Chef que se equipe el arma de forma TEMPORAL
		body.equipar_cuchillo()
		
		# 2. BORRAMOS la línea que guardaba en el GameManager.
		# Ahora el cuchillo solo se vuelve permanente cuando el Chef 
		# ejecute 'actualizar_checkpoint'.
		
		# 3. El ítem desaparece del suelo
		queue_free()
