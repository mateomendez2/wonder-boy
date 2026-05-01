# Script del Cartel2 (Checkpoint.gd)
extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# Le avisamos al Chef que este es su nuevo punto de aparición
		body.actualizar_checkpoint(global_position)
		
		# --- NUEVO: GUARDAMOS EL ESTADO EN EL GAMEMANAGER ---
		# Aseguramos los puntos que juntaste hasta acá
		GameManager.checkpoint_puntos = GameManager.puntos_confirmados
		
		# Si querés que también reviva con la energía exacta que tenía al tocar el cartel:
		GameManager.checkpoint_energia = GameManager.energia_actual
		# ----------------------------------------------------
		
		# Opcional: Podés desactivar el checkpoint para que no se active mil veces
		# set_deferred("monitoring", false)
