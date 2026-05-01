extends RigidBody2D

# --- CONFIGURACIÓN DE IMÁGENES ---
@export var imagen_roto: Texture2D    # Aquí arrastrá la de CalderoRoto
@export var imagen_humo: Texture2D    # Aquí arrastrá la de HumoCaldero

# --- NUEVO: EL SELECTOR DE ÍTEMS ---
enum TipoItem { CUCHILLO, CARRITO, SARTEN }
@export var que_suelta: TipoItem = TipoItem.CUCHILLO

# Arrastrá acá tus dos escenas de ítems (.tscn) desde el panel de archivos
@export var escena_cuchillo: PackedScene
@export var escena_carrito: PackedScene
@export var escena_sarten: PackedScene
# -----------------------------------

@export var fuerza_x: float = 200.0 
@export var fuerza_y: float = -300.0

var lanzado = false

func _ready() -> void:
	# Si el caldero está configurado para dar el cuchillo...
	if que_suelta == TipoItem.CUCHILLO:
		# ...ahora le preguntamos a la memoria del NIVEL ANTERIOR:
		if GameManager.trajo_cuchillo == true:
			queue_free() 
			return 
	
	freeze = true
	contact_monitor = true
	max_contacts_reported = 1

func _on_area_deteccion_chef_body_entered(body: Node2D) -> void:
	if body.name.to_lower() == "chef" and not lanzado:
		# Le decimos a este cuerpo rígido (el caldero) que ignore
		# completamente los choques sólidos con el 'body' (el Chef).
		add_collision_exception_with(body)
		
		lanzar_caldero()

func lanzar_caldero() -> void:
	lanzado = true
	
	# 1. Cambiamos la imagen a CalderoRoto apenas despega
	if imagen_roto:
		$Sprite2D.texture = imagen_roto
	
	set_deferred("freeze", false)
	$AreaDeteccionChef.set_deferred("monitoring", false)
	
	await get_tree().process_frame
	apply_central_impulse(Vector2(fuerza_x, fuerza_y))

# --- AL TOCAR EL PASTO ---
func _on_body_entered(body: Node) -> void:
	if lanzado:
		# Verificamos si es el suelo
		if body.name == "Pasto" or body is TileMap:
			estrellarse()

func estrellarse() -> void:
	# En vez de "freeze = true", le pedimos a Godot que lo congele 
	# apenas termine de calcular el choque con el piso.
	set_deferred("freeze", true)
	
	if imagen_humo:
		$Sprite2D.texture = imagen_humo
		$Sprite2D.scale = Vector2(1.0, 1.0)
	
	await get_tree().create_timer(0.1).timeout
	
	# --- NUEVA LÓGICA DE SOLTAR EL BOTÍN ---
	var botin = null
	
	if que_suelta == TipoItem.CUCHILLO and escena_cuchillo:
		botin = escena_cuchillo.instantiate()
	elif que_suelta == TipoItem.CARRITO and escena_carrito:
		botin = escena_carrito.instantiate()
	elif que_suelta == TipoItem.SARTEN and escena_sarten:
		botin = escena_sarten.instantiate()
		
	# Si logramos crear el botín, lo ponemos en el mundo
	if botin:
		botin.global_position = global_position 
		get_parent().add_child(botin)
	# ---------------------------------------
		
	queue_free()
