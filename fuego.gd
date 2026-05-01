extends Area2D

var ya_extinto: bool = false # Para evitar que se apague dos veces seguidas

@export var escena_humo: PackedScene
@export var escena_puntaje: PackedScene # <--- AQUÍ VA TU ESCENA DE NÚMEROS
@export var imagen_puntaje: Texture2D  # <--- AQUÍ VA EL PNG DEL 50 ROJO
@export var puntos_sarten: int = 50

func extinguir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if ya_extinto: return
	ya_extinto = true
	
	# Desactivamos colisiones y lo ocultamos al instante
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	
	# 1. Hacemos aparecer el humo al apagarlo
	if escena_humo != null:
		var nuevo_humo = escena_humo.instantiate()
		nuevo_humo.global_position = global_position
		get_tree().current_scene.add_child(nuevo_humo)
	
	# 2. Si fue con la sartén, damos puntos y mostramos el cartel
	if por_sarten:
		if escena_puntaje != null and imagen_puntaje != null:
			var cartel = escena_puntaje.instantiate()
			cartel.texture = imagen_puntaje
			cartel.global_position = global_position
			get_tree().current_scene.add_child(cartel)
		
		if nodo_chef != null and nodo_chef.has_method("sumar_puntos"):
			nodo_chef.sumar_puntos(puntos_sarten)
			
		# --- NUEVO: SONIDO DE DESTRUCCIÓN POR SARTÉN ---
		$SonidoDestruccion.play()
		await $SonidoDestruccion.finished # Esperamos a que termine el ruidito del premio
		# ---------------------------------------
		
		queue_free()
	else:
		# 3. Si se apaga con un arma normal, desaparece sin esperar sonido de puntos
		queue_free()

# --- DETECCIÓN DE GOLPES ---

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# Si el Chef viene con la sartén activada, apaga el fuego con premio
		if body.tiempo_sarten > 0:
			extinguir(true, body)
		# Si viene normal sin sartén, el Chef se quema
		elif body.has_method("recibir_dano"):
			body.recibir_dano()

func _on_area_entered(area: Area2D) -> void:
	# Si la sartén giratoria lo toca
	if area.is_in_group("escudo"):
		var chef = get_tree().current_scene.get_node("Chef")
		extinguir(true, chef)
	# Si lo toca cualquier otra arma (hacha/cuchillo), se apaga pero sin puntos
	elif area.is_in_group("armas"):
		extinguir(false)
