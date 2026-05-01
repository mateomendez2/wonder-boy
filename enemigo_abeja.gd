extends Area2D

@export var velocidad_avance = 40.0
@export var radio_circulo = 25.0
@export var velocidad_giro = 5.0
@export var escena_humo: PackedScene

# --- NUEVAS VARIABLES PARA PUNTAJE ---
@export var escena_puntaje: PackedScene
@export var imagen_puntaje: Texture2D
@export var puntos_sarten: int = 50
# -------------------------------------

@export var viene_de_izquierda: bool = false
@export var escondida_al_inicio: bool = false # <--- EL NUEVO MODO FANTASMA

var tiempo = 0.0
var posicion_inicial_y = 0.0
var muerto = false
var activo = false 

var velocidad_y: float = 0.0
var gravedad: float = 980.0

func _ready():
	posicion_inicial_y = global_position.y
	
	if viene_de_izquierda:
		$AnimatedSprite2D.flip_h = true
		
	# Si está en modo emboscada, la hacemos invisible e intocable
	if escondida_al_inicio:
		$AnimatedSprite2D.visible = false
		$CollisionShape2D.set_deferred("disabled", true)

func _process(delta):
	if muerto:
		velocidad_y += gravedad * delta
		global_position.y += velocidad_y * delta
		return 
	
	if not activo:
		return
	
	tiempo += delta * velocidad_giro
	
	if viene_de_izquierda:
		global_position.x += velocidad_avance * delta 
	else:
		global_position.x -= velocidad_avance * delta 
	
	var desfase_y = sin(tiempo) * radio_circulo
	global_position.y = posicion_inicial_y + desfase_y

# --- FUNCIÓN MORIR ACTUALIZADA CON PUNTOS Y SONIDO ---
func morir(por_sarten: bool = false, nodo_chef: Node2D = null) -> void:
	if muerto: return 
	muerto = true
	
	$CollisionShape2D.set_deferred("disabled", true)
	$Radar/CollisionShape2D.set_deferred("disabled", true)
	
	if por_sarten:
		if escena_humo != null:
			var nuevo_humo = escena_humo.instantiate()
			nuevo_humo.global_position = global_position
			get_tree().current_scene.add_child(nuevo_humo)
			
		# --- CARTEL DE PUNTAJE Y SUMA ---
		if escena_puntaje != null and imagen_puntaje != null:
			var cartel = escena_puntaje.instantiate()
			cartel.texture = imagen_puntaje
			cartel.global_position = global_position
			get_tree().current_scene.add_child(cartel)
			
		if nodo_chef != null and nodo_chef.has_method("sumar_puntos"):
			nodo_chef.sumar_puntos(puntos_sarten)
		# --------------------------------
			
		hide()
		
		# --- NUEVO: SONIDO DE DESTRUCCIÓN POR SARTÉN ---
		$SonidoDestruccion.play()
		await $SonidoDestruccion.finished # Esperamos a que termine de sonar
		# ---------------------------------------
		
		queue_free()
	else:
		velocidad_y = -300.0 
		$AnimatedSprite2D.play("Cae")
		
		# --- SONIDO MUERTE POR ARMA (Normal) ---
		$SonidoMuerte.play() # Acá no hace falta el 'await' porque abajo ya tenés un Timer de 1.5s
		# ---------------------------------------
		
		await get_tree().create_timer(1.5).timeout
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		if body.tiempo_sarten > 0:
			morir(true, body) # ACTUALIZADO: Le pasamos el Chef para los puntos
		else:
			body.recibir_dano() 
			
	elif body.is_in_group("armas"):
		morir(false) 
		body.queue_free()

func _on_radar_body_entered(body: Node2D) -> void:
	if body.name == "Chef" and not activo:
		activo = true
		
		# ¡SORPRESA! Se hace visible y letal de golpe
		if escondida_al_inicio:
			$AnimatedSprite2D.visible = true
			$CollisionShape2D.set_deferred("disabled", false)
			
		$AnimatedSprite2D.play("Vuela")

# --- NUEVO: DETECCIÓN DE LA SARTÉN ORBITAL ---
func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("armas"):
		if area.is_in_group("escudo"):
			# Si es la sartén giratoria, buscamos al chef en la escena
			var chef = get_tree().current_scene.get_node("Chef")
			morir(true, chef)
		else:
			morir(false) # Cuchillo/hacha normal
			area.queue_free()
