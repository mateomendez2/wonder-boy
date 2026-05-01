extends Area2D

var roto: bool = false # Barrera para que no se rompa dos veces a la vez

@export var escena_humo: PackedScene
@export var escena_puntaje: PackedScene # <--- AQUÍ VA TU ESCENA DE NÚMEROS
@export var imagen_puntaje: Texture2D  # <--- AQUÍ VA EL PNG DEL 50 ROJO
@export var puntos_sarten: int = 50

func morir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if roto: return
	roto = true
	
	# Apagamos colisiones y ocultamos la roca al instante
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	
	# 1. Hacemos aparecer el humo
	if escena_humo != null:
		var nuevo_humo = escena_humo.instantiate()
		nuevo_humo.global_position = global_position
		get_tree().current_scene.add_child(nuevo_humo)
		
	# 2. Si fue con la sartén, damos puntos y mostramos el cartel rojo
	if por_sarten:
		if escena_puntaje != null and imagen_puntaje != null:
			var cartel = escena_puntaje.instantiate()
			cartel.texture = imagen_puntaje
			cartel.global_position = global_position
			get_tree().current_scene.add_child(cartel)
		
		# Sumamos los puntos al Chef
		if nodo_chef != null and nodo_chef.has_method("sumar_puntos"):
			nodo_chef.sumar_puntos(puntos_sarten)
			
		# --- NUEVO: SONIDO DE DESTRUCCIÓN POR SARTÉN ---
		$SonidoDestruccion.play()
		await $SonidoDestruccion.finished # Esperamos a que termine el ruidito de puntos
		# ---------------------------------------
		
		queue_free()
	else:
		# 3. Si se rompe con un cuchillo normal, se borra directo (no da puntos ni suena el premio)
		queue_free()

# --- DETECCIÓN DE GOLPES ---

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# Si el Chef viene con la sartén activada, rompe la roca y cobra premio
		if body.tiempo_sarten > 0:
			morir(true, body)
		# Si viene normal sin sartén, el Chef se lastima
		elif body.has_method("recibir_dano"):
			body.recibir_dano()

func _on_area_entered(area: Area2D) -> void:
	# Si la sartén giratoria la toca
	if area.is_in_group("escudo"):
		var chef = get_tree().current_scene.get_node("Chef")
		morir(true, chef)
	# Si la toca cualquier otra arma (ej: hacha/cuchillo), se rompe pero sin dar puntos
	elif area.is_in_group("armas"):
		morir(false)
		area.queue_free() # Destruye el cuchillo/hacha tras el impacto
