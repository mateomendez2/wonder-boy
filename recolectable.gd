extends Area2D

# --- VARIABLES PARA EL PUNTAJE FLOTANTE ---
@export var escena_puntaje: PackedScene # Acá va puntaje_flotante.tscn
@export var imagen_puntaje: Texture2D   # Acá va tu imagen Puntaje50
# ----------------------------------------

@export var puntos_que_da: int = 50

func _ready() -> void:
	$Sprite2D.hide()
	$CollisionShape2D.set_deferred("disabled", true)

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	await get_tree().create_timer(0.2).timeout
	$Sprite2D.show()
	$CollisionShape2D.set_deferred("disabled", false)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		
		# --- ¡NUEVO! ESCONDEMOS LA FRUTA DE INMEDIATO ---
		# Para que parezca que ya la agarramos mientras suena el audio
		$Sprite2D.hide()
		$CollisionShape2D.set_deferred("disabled", true)
		# ------------------------------------------------
		
		# --- 1. LE DAMOS LOS PUNTOS AL CHEF ---
		# Usamos tu variable exportada para que sirva para cualquier fruta (manzana, banana, etc.)
		body.sumar_puntos(puntos_que_da)
		# --------------------------------------
		
		# --- 2. HACEMOS APARECER EL CARTELITO ---
		if escena_puntaje:
			var nuevo_puntaje = escena_puntaje.instantiate()
			nuevo_puntaje.texture = imagen_puntaje
			nuevo_puntaje.global_position = global_position
			get_tree().current_scene.add_child(nuevo_puntaje)
		# -------------------------------------
		
		# --- ESTO ES LO NUEVO PARA LOS RELOJES ---
		var cuartos_recuperados = 1 # 4 cuartos = 1 reloj entero
		GameManager.energia_actual += cuartos_recuperados
		
		# Evitamos que se pase del máximo (32 puntos)
		if GameManager.energia_actual > GameManager.energia_maxima:
			GameManager.energia_actual = GameManager.energia_maxima
			
		# Le decimos al Chef que redibuje los relojes en pantalla
		if body.has_method("actualizar_relojes"):
			body.actualizar_relojes()
		# ------------------------------------------
		print("¡Ñam! Agarraste un ítem de ", puntos_que_da, " puntos.")
		
		# --- ¡NUEVO! REPRODUCIR SONIDO Y ESPERAR ---
		$SonidoAgarre.play()
		await $SonidoAgarre.finished
		# -------------------------------------------
		
		queue_free()
