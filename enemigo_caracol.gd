extends Area2D

const VELOCIDAD = 8.0 
var despertó: bool = false

# 1. ACÁ ESTÁ LA VARIABLE CORRECTA
var esta_muerto: bool = false 

@export var escena_humo: PackedScene
@export var escena_puntaje: PackedScene 
@export var imagen_puntaje: Texture2D  
@export var puntos_sarten: int = 50

var velocidad_y: float = 0.0
# 2. AGREGAMOS LA VARIABLE PARA EL REBOTE HACIA ATRÁS
var velocidad_x: float = 0.0 
var gravedad: float = 980.0

func _process(delta: float) -> void:
	if esta_muerto:
		velocidad_y += gravedad * delta
		position.y += velocidad_y * delta
		# 3. LE DECIMOS QUE USE EL EMPUJE MIENTRAS CAE
		position.x += velocidad_x * delta 
		return 

	if despertó:
		position.x -= VELOCIDAD * delta 
		$AnimatedSprite2D.play("Camina")

func _on_radar_body_entered(body: Node2D) -> void:
	if body.name == "Chef" and not esta_muerto:
		despertó = true

func morir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if esta_muerto: return 
	esta_muerto = true
	
	# Apagamos colisiones
	$CollisionShape2D.set_deferred("disabled", true)
	
	if por_sarten:
		# --- MUERTE ARCADE CON SARTÉN (Humo y puntos) ---
		if escena_humo != null:
			var nuevo_humo = escena_humo.instantiate()
			nuevo_humo.global_position = global_position
			get_tree().current_scene.add_child(nuevo_humo)
			
		if escena_puntaje != null and imagen_puntaje != null:
			var cartel = escena_puntaje.instantiate()
			cartel.texture = imagen_puntaje
			cartel.global_position = global_position
			get_tree().current_scene.add_child(cartel)
			
		if nodo_chef != null and nodo_chef.has_method("sumar_puntos"):
			nodo_chef.sumar_puntos(puntos_sarten)
			
		hide() 
		
		# --- NUEVO: SONIDO DE DESTRUCCIÓN POR SARTÉN ---
		$SonidoDestruccion.play()
		await $SonidoDestruccion.finished # Frenamos el borrado para que termine de sonar
		# ---------------------------------------
		
		queue_free()
	else:
		# --- MUERTE NORMAL CON CUCHILLO: REBOTE HACIA LA DERECHA ---
		velocidad_y = -250.0 # Salto hacia arriba
		velocidad_x = 80.0   # Empuje hacia la derecha constante
		
		# --- SONIDO MUERTE NORMAL ---
		$SonidoMuerte.play() 
		# -----------------------------------
		
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.play("Muerto") 
		
		# Espera un segundo y medio mientras cae, y después se borra
		await get_tree().create_timer(1.5).timeout
		queue_free()
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		if body.tiempo_sarten > 0:
			morir(true, body) # Sartén activada: le pasamos el chef
		elif body.en_vehiculo:
			body.recibir_dano() 
			morir(true, body) # El carrito también lo "pisa" con humo
		else:
			body.recibir_dano() 
		
	elif body.is_in_group("armas"):
		morir(false) # Muerte normal por hacha
		body.queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("armas"):
		if area.is_in_group("escudo"):
			# Si es la sartén giratoria, buscamos al chef en la escena
			var chef = get_tree().current_scene.get_node("Chef")
			morir(true, chef)
		else:
			morir(false) # Cuchillo/hacha normal
			area.queue_free()
