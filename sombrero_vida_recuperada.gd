extends Area2D

func _ready() -> void:
	# --- SISTEMA ANTI-BUCLE ---
	if GameManager.sombrero_recogido == true:
		queue_free()
		return
	# --------------------------

	# Arranque normal (invisible)
	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	await get_tree().create_timer(0.2).timeout
	$Sprite2D.show()
	$CollisionShape2D.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		
		# --- NUEVO: SONIDO Y DESAPARICIÓN VISUAL ---
		# Lo apagamos rápido para que no parezca que sigue ahí mientras suena
		$CollisionShape2D.set_deferred("disabled", true)
		$Sprite2D.hide()
		$SonidoPoder.play()
		# -------------------------------------------
		
		# Sumamos la vida si tiene menos de 3
		if GameManager.vidas_actuales < 3:
			GameManager.vidas_actuales += 1
			print("¡Vida extra conseguida! Vidas actuales: ", GameManager.vidas_actuales)
			
			if body.has_method("actualizar_vidas"):
				body.actualizar_vidas()
		
		# Guardamos que ya lo agarró
		GameManager.sombrero_recogido = true
		
		# --- ESPERAMOS AL AUDIO ANTES DE ELIMINAR EL NODO ---
		await $SonidoPoder.finished
		queue_free()
