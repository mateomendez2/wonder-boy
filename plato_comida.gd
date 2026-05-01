extends Area2D

@export var escena_puntaje: PackedScene # Acá va puntaje_flotante.tscn
@export var imagen_puntaje: Texture2D   # Acá va tu imagen de 1000 puntos

var puntos_que_da: int = 1000

func _ready() -> void:
	# Arranca invisible y no se puede agarrar todavía
	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	# Cuando la cámara lo ve, espera 0.2s y aparece de golpe
	await get_tree().create_timer(0.2).timeout
	$Sprite2D.show()
	$CollisionShape2D.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# --- NUEVO: SONIDO Y DESAPARICIÓN VISUAL ---
		# Desactivamos colisiones y ocultamos para que no se agarre dos veces
		$CollisionShape2D.set_deferred("disabled", true)
		$Sprite2D.hide()
		
		$SonidoAgarre.play()
		# -------------------------------------------
		
		# 1. Le damos los puntos
		body.sumar_puntos(puntos_que_da)
		
		# 2. Avisamos al GameManager para el menú final
		GameManager.plato_recogido = true
		
		# 3. Hacemos flotar el cartelito de 1000
		if escena_puntaje:
			var nuevo_puntaje = escena_puntaje.instantiate()
			nuevo_puntaje.texture = imagen_puntaje
			nuevo_puntaje.global_position = global_position
			get_tree().current_scene.add_child(nuevo_puntaje)
		
		print("¡Encontraste el Plato de Comida: +1000 puntos!")
		
		# --- ESPERAMOS A QUE TERMINE EL AUDIO ANTES DE BORRAR ---
		await $SonidoAgarre.finished
		queue_free()
