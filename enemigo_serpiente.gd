extends Area2D

var muerto: bool = false
var velocidad_y: float = 0.0
var gravedad: float = 980.0

@export var escena_humo: PackedScene
@export var escena_puntaje: PackedScene
@export var imagen_puntaje: Texture2D
@export var puntos_sarten: int = 50

# --- VARIABLES PARA EL TEMBLOR ---
var posicion_inicial_x: float = 0.0
var tiempo_movimiento: float = 0.0
@export var velocidad_temblor: float = 0.15 

func _ready() -> void:
	posicion_inicial_x = global_position.x
	$AnimatedSprite2D.play("Quieto")

func _process(delta: float) -> void:
	# BARRERA: Si está muerta, deja de temblar y empieza a caer
	if muerto:
		velocidad_y += gravedad * delta
		global_position.y += velocidad_y * delta
		return 

	# --- LÓGICA DEL PIXEL (TIC NERVIOSO) ---
	tiempo_movimiento += delta
	if tiempo_movimiento >= velocidad_temblor:
		tiempo_movimiento = 0.0 
		if global_position.x == posicion_inicial_x:
			global_position.x = posicion_inicial_x - 1.0
		else:
			global_position.x = posicion_inicial_x

func morir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if muerto: return 
	muerto = true
	
	# Apagamos las colisiones apenas muere para que no lastime más al Chef
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
		# --- MUERTE NORMAL CON CUCHILLO (Saltito y caída) ---
		velocidad_y = -300.0 
		
		# --- SONIDO MUERTE NORMAL ---
		$SonidoMuerte.play() # Acá suena tranquilo porque abajo tiene el Timer
		# -----------------------------------
		
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.play("Muerto") 
		
		# Espera un segundo y medio mientras cae, y después se borra
		await get_tree().create_timer(1.5).timeout
		queue_free()

# --- DETECCIÓN DE GOLPES ---
func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		if body.tiempo_sarten > 0:
			morir(true, body)
		else:
			body.recibir_dano()
	# Si un cuerpo físico que es arma la toca (el cuchillo volador)
	elif body.is_in_group("armas"):
		morir(false)
		body.queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("armas"):
		if area.is_in_group("escudo"):
			var chef = get_tree().current_scene.get_node("Chef")
			morir(true, chef)
		else:
			morir(false)
			area.queue_free()
