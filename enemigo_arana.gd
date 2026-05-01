extends Area2D

var muerto: bool = false
var velocidad_y: float = 0.0
var velocidad_x: float = 0.0 # <-- NUEVO: Empuje lateral para cuando muere
var gravedad: float = 980.0

@export var escena_humo: PackedScene
@export var escena_puntaje: PackedScene
@export var imagen_puntaje: Texture2D
@export var puntos_sarten: int = 50

# --- VARIABLES PARA EL FLOTE VERTICAL ---
var posicion_inicial_y: float = 0.0
var tiempo_movimiento: float = 0.0
@export var velocidad_flote: float = 5.0 # Qué tan rápido sube y baja
@export var amplitud_flote: float = 30.0 # Cuántos píxeles recorre hacia arriba y abajo

func _ready() -> void:
	# Guardamos la altura en la que pusiste a la araña en el editor
	posicion_inicial_y = global_position.y
	$AnimatedSprite2D.play("Moverse")

func _process(delta: float) -> void:
	# BARRERA: Si muere por cuchillo, hace la parábola (arco) de caída
	if muerto:
		velocidad_y += gravedad * delta
		global_position.y += velocidad_y * delta
		global_position.x += velocidad_x * delta # <-- La mueve a la derecha mientras cae
		return 

	# --- LÓGICA DE FLOTE (ARRIBA Y ABAJO SUAVE) ---
	tiempo_movimiento += delta
	# La función sin() crea un vaivén perfecto y suave, ideal para cosas que flotan o cuelgan
	global_position.y = posicion_inicial_y + sin(tiempo_movimiento * velocidad_flote) * amplitud_flote


func morir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if muerto: return 
	muerto = true
	
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
		
		# --- NUEVO: SONIDO MUERTE POR SARTÉN ---
		$SonidoMuerte.play()
		await $SonidoMuerte.finished # Frenamos el borrado para que termine de sonar
		# ---------------------------------------
		
		queue_free()
	else:
		# --- MUERTE NORMAL CON CUCHILLO: REBOTE HACIA LA DERECHA ---
		velocidad_y = -250.0 # Salto hacia arriba
		velocidad_x = 80.0   # Empuje hacia la derecha constante
		
		# --- NUEVO: SONIDO MUERTE NORMAL ---
		$SonidoMuerte.play() # Acá suena tranquilo porque abajo tiene el Timer
		# -----------------------------------
		
		$AnimatedSprite2D.stop()
		$AnimatedSprite2D.play("Morir") 
		
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
