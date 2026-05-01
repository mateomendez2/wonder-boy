extends CharacterBody2D

const SPEED = 130.0
const JUMP_VELOCITY = -350.0
var nivel_terminado: bool = false
const ACELERACION = 500.0  # Qué tan rápido llega a la velocidad máxima
const FRICCION = 500.0    # Qué tan rápido clava los frenos (más alto = menos patinaje)

var vidas: int = 3
var checkpoint_actual: Vector2
var checkpoint_camara_y: float # <-- NUEVO: Guarda la altura de la vista
var puntos_actuales_tramo: int = 0
var en_vehiculo: bool = false
const SPEED_CARRITO = 200.0 # Más rápido que los 130 normales

var rampa_actual: Area2D = null
var memoria_x_rampa: float = -9999.0

@export var escena_humo: PackedScene # Acá vamos a arrastrar el humo_caldero.tscn

var tiene_cuchillo: bool = false
@export var escena_proyectil: PackedScene # Acá arrastraremos el cuchillo_proyectil.tscn

var esta_lanzando: bool = false

# 1 = derecha, -1 = izquierda. Arranca mirando a la derecha.
var direccion_mirada: int = 1
var tiempo_sarten: float = 0.0
var tiempo_flotacion: float = 0.0 # Controla el vaivén del flote

# --- IMÁGENES DE LOS RELOJES ---
@export var img_reloj_4: Texture2D # Reloj Lleno (100%)
@export var img_reloj_3: Texture2D # Reloj 3/4
@export var img_reloj_2: Texture2D # Reloj 1/2
@export var img_reloj_1: Texture2D # Reloj 1/4
@export var img_reloj_0: Texture2D # Reloj Vacío (0%)

# --- IMÁGENES DEL CUCHILLO ---
@export var img_cuchillo_prendido: Texture2D # Acá va CuchilloCocinaHUD1 (con color)
@export var img_cuchillo_apagado: Texture2D  # Acá va CuchilloCocinaHUD2 (apagado)
@export var img_carrito_prendido: Texture2D
@export var img_carrito_apagado: Texture2D
@export var img_sarten_prendida: Texture2D
@export var img_sarten_apagada: Texture2D

# --- VARIABLES DE TIEMPO ---
var temporizador_reloj: float = 0.0
const TIEMPO_RESTA: float = 2.0 # Cada cuántos segundos pierde 1/4 de reloj

func _ready() -> void:
	# --- 1. RECUPERAMOS EL CUCHILLO SIEMPRE ---
	# (Al sacarlo del IF, funciona tanto en checkpoints como al arrancar niveles nuevos)
	if GameManager.cuchillo_guardado == true or GameManager.trajo_cuchillo == true:
		tiene_cuchillo = true
	else:
		tiene_cuchillo = false

	# --- 2. LÓGICA DE CHECKPOINT ---
	# Si la mochila global tiene un checkpoint guardado, nos movemos ahí
	if GameManager.checkpoint_pos != Vector2.ZERO:
		global_position = GameManager.checkpoint_pos
		$Camera2D.global_position.y = GameManager.checkpoint_camara_y
		actualizar_marcador()
	
	# --- 3. PREPARACIÓN VISUAL Y HUD ---
	$PivoteSarten.hide() 
	$PivoteSarten.set_as_top_level(true)
	
	actualizar_relojes()
	actualizar_vidas()
	actualizar_icono_cuchillo()
	actualizar_icono_carrito()
	actualizar_icono_sarten()
	
	# --- TRUCO DE CALENTAMIENTO (A partir de acá dejá todo lo que ya tenías) ---
	$AnimatedSprite2D.play("Camina")
	$AnimatedSprite2D.play("Salta")
	$AnimatedSprite2D.play("Lanza")
	if escena_humo != null:
		$AnimatedSprite2D.play("Carrito_Camina") # Por si agarrás el carrito
	
	# Y al final lo volvemos a dejar quietito para cuando se levante el telón
	$AnimatedSprite2D.play("Estatico") 
	# ------------------------------------------------------------
	
	# --- TELÓN NEGRO (Ocultar tirones de carga) ---
	var telon = get_parent().get_node("HUD/TelonNegro")
	
	if telon != null:
		telon.show() 
		telon.modulate.a = 1.0 
		
		var tween_telon = create_tween()
		tween_telon.tween_property(telon, "modulate:a", 0.0, 1.0)
		
func _physics_process(delta: float) -> void:
	# --- SISTEMA DE TIEMPO (Se agota la vida) ---
	if GameManager.energia_actual > 0:
		temporizador_reloj += delta
		if temporizador_reloj >= TIEMPO_RESTA:
			temporizador_reloj = 0.0 # Reiniciamos el cronómetro
			GameManager.energia_actual -= 1 # Le sacamos 1/4 de reloj
			actualizar_relojes() # Actualizamos el dibujo
			
			if GameManager.energia_actual <= 0:
				procesar_muerte(true)
	# --------------------------------------------
	
	# 1. Aplicar Gravedad con truco de "Tiempo de Suspensión"
	if not is_on_floor():
		var gravedad_actual = get_gravity()
		
		# Si el Chef está cerca del punto más alto (velocidad y entre -100 y 100)
		if abs(velocity.y) < 100:
			# Reducimos la gravedad a la mitad para que flote más
			velocity += gravedad_actual * 1 * delta
		else:
			# Gravedad normal
			velocity += gravedad_actual * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$SonidoSalto.play()
		
	# --- SALTO VARIABLE ---
	# Si suelta la tecla espacio Y además el Chef sigue yendo hacia arriba (y < 0)
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		# Le cortamos el impulso a la mitad multiplicando por 0.5
		velocity.y *= 0.5
	# ----------------------

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = 0
	if nivel_terminado == true:
		direction = 1
	else:
		direction = Input.get_axis("ui_left", "ui_right")
	
	# Guardamos de forma manual y segura si va a 1 o a -1
	if direction > 0:
		direccion_mirada = 1
	elif direction < 0:
		direccion_mirada = -1
		
	# Y movemos el PuntoDisparo (fuera del if/elif)
	if direction != 0:
		$PuntoDisparo.position.x = abs($PuntoDisparo.position.x) * direccion_mirada
		
	# --- CÓDIGO DE MOVIMIENTO ANTI-PATINAJE Y CARRITO ---
	if en_vehiculo:
		var velocidad_empuje = 15.0 # Esta es la velocidad a la que avanza solo
		var velocidad_objetivo = velocidad_empuje
		
		# Si aprieta la flecha derecha, acelera hasta la velocidad máxima
		if direction > 0:
			velocidad_objetivo = SPEED_CARRITO
		
		# Aplicamos el movimiento hacia esa velocidad
		velocity.x = move_toward(velocity.x, velocidad_objetivo, ACELERACION * delta)
		
		# Bloqueamos la mirada: en el carrito NO se puede mirar para atrás
		direccion_mirada = 1
		$AnimatedSprite2D.flip_h = false 
	else:
		# COMPORTAMIENTO NORMAL A PIE
		if direction:
			# Acelera progresivamente hasta llegar a SPEED
			velocity.x = move_toward(velocity.x, direction * SPEED, ACELERACION * delta)
		else:
			# Frena progresivamente usando la FRICCION
			velocity.x = move_toward(velocity.x, 0, FRICCION * delta)
	# ------------------------------------------
		
	# --- CÓDIGO DE ANIMACIÓN ---
	if direction != 0:
		$AnimatedSprite2D.flip_h = direction < 0 

	# Elegimos qué animación reproducir (SOLO si NO está lanzando)
	if not esta_lanzando:
		if en_vehiculo:
			# --- ANIMACIONES DEL CARRITO ---
			if not is_on_floor():
				$AnimatedSprite2D.play("Carrito_Salta")
			elif velocity.x != 0: # Cambiamos 'direction' por 'velocity.x' para que detecte el empuje automático
				$AnimatedSprite2D.play("Carrito_Camina")
			else:
				$AnimatedSprite2D.play("Carrito_Estatico")
		else:
			# --- ANIMACIONES NORMALES (A PIE) ---
			if not is_on_floor():
				$AnimatedSprite2D.play("Salta")
			elif direction != 0:
				$AnimatedSprite2D.play("Camina")
			else:
				$AnimatedSprite2D.play("Estatico")

	# --- CÓDIGO DE DISPARO ---
	# Le sacamos el candado de "not en_vehiculo"
	if Input.is_action_just_pressed("lanzar") and tiene_cuchillo and not esta_lanzando:
		
		esta_lanzando = true # Prendemos el seguro
		$SonidoLanzamiento.play()
		
		# --- ELEGIMOS QUÉ ANIMACIÓN DE ATAQUE USAR ---
		if en_vehiculo:
			$AnimatedSprite2D.play("Carrito_Lanza") # Tu animación nueva
		else:
			$AnimatedSprite2D.play("Lanza") # La de siempre
		# ---------------------------------------------
		
		var nuevo_proyectil = escena_proyectil.instantiate()
		nuevo_proyectil.direccion_vuelo = int(direccion_mirada)
		nuevo_proyectil.global_position = $PuntoDisparo.global_position
		get_tree().current_scene.add_child(nuevo_proyectil)
		nuevo_proyectil.add_collision_exception_with(self)
		
		await $AnimatedSprite2D.animation_finished
		
		esta_lanzando = false 
	# -------------------------
		
	move_and_slide()
	
		# --- CÓDIGO DE CÁMARA ARCADE DEFINITIVO ---
	var mitad_pantalla = get_viewport_rect().size.x / 2.0
	var linea_de_empuje = 120
	var posicion_ideal_x = global_position.x - linea_de_empuje + mitad_pantalla
	var posicion_futura = max($Camera2D.global_position.x, posicion_ideal_x)
	var x_final_camara = max(mitad_pantalla, posicion_futura)
	
	$Camera2D.global_position.x = round(x_final_camara)
	
	# 4. Movimiento Vertical (Cámara sobre rieles CON AMORTIGUADOR)
	if rampa_actual != null:
		var punto_a = rampa_actual.get_node("PuntoInicio").global_position
		var punto_b = rampa_actual.get_node("PuntoFin").global_position
		
		# --- LA MAGIA DE LA MEMORIA ---
		# Si recién tocamos la rampa, sincronizamos la memoria con el Chef
		if memoria_x_rampa == -9999.0:
			memoria_x_rampa = global_position.x
			
		# La memoria SOLO crece hacia adelante (derecha), nunca hacia atrás
		memoria_x_rampa = max(memoria_x_rampa, global_position.x)
		
		# Calculamos la altura usando la MEMORIA, no la posición actual del Chef
		var x_segura = clamp(memoria_x_rampa, punto_a.x, punto_b.x)
		var altura_ideal = remap(x_segura, punto_a.x, punto_b.x, punto_a.y, punto_b.y)
		# ------------------------------
		
		$Camera2D.global_position.y = lerp($Camera2D.global_position.y, altura_ideal - 40, 25.0 * delta)
	else:
		# Reseteamos la memoria cuando salimos de la rampa (por salto o caída)
		memoria_x_rampa = -9999.0
		
		var distancia_y = global_position.y - $Camera2D.global_position.y
		if distancia_y > 40: 
			$Camera2D.global_position.y += (distancia_y - 40)
		elif distancia_y < -90: 
			$Camera2D.global_position.y += (distancia_y + 90)
			
	# 5. Choque contra el borde izquierdo (La pared de cristal)
	var borde_izquierdo_real = $Camera2D.global_position.x - mitad_pantalla
	var distancia_al_borde = 10 
	
	if global_position.x < borde_izquierdo_real + distancia_al_borde:
		global_position.x = round(borde_izquierdo_real + distancia_al_borde)
	# ------------------------------------------
		
	# --- LÓGICA DE LA SARTÉN FLOTANTE CON RETRASO REAL ---
	# --- LÓGICA DE LA SARTÉN FLOTANTE ---
	if tiempo_sarten > 0:
		tiempo_sarten -= delta
		tiempo_flotacion += delta
		
		# --- REFUERZO DE SILENCIO (Para que no se pisen las músicas) ---
		var musica_nivel = get_tree().current_scene.get_node_or_null("MusicaFondo")
		if musica_nivel != null and musica_nivel.stream_paused == false:
			musica_nivel.stream_paused = true
		# -----------------------------------

		# 1. El flote matemático
		var flote_y = sin(tiempo_flotacion * 5.0) * 4.0
		var flote_x = cos(tiempo_flotacion * 3.0) * 2.0
		var posicion_atras = -25.0 * direccion_mirada 
		var objetivo_global = global_position + Vector2(posicion_atras + flote_x, -20.0 + flote_y)
		
		$PivoteSarten.global_position = $PivoteSarten.global_position.lerp(objetivo_global, 8.0 * delta)
		invulnerable = true
		
		# --- NUEVO: CUANDO SE TERMINA EL TIEMPO (CORREGIDO) ---
		if tiempo_sarten <= 0:
			invulnerable = false
			$PivoteSarten.hide()
			actualizar_icono_sarten()
			
			# 1. Apagamos el sonido de la sartén
			$SonidoCarrito.stop() 
			
			# 2. Le devolvemos el volumen al nivel
			if musica_nivel != null:
				musica_nivel.stream_paused = false
				print("Sartén terminada: Volviendo a música de fondo")
		
		# --- CUANDO SE TERMINA EL TIEMPO ---
		if tiempo_sarten <= 0:
			invulnerable = false
			$PivoteSarten.hide()
			actualizar_icono_sarten()
			
			# --- NUEVO: APAGAR MÚSICA SARTÉN Y VOLVER AL NIVEL ---
			$SonidoCarrito.stop() # Apagamos la música de invencibilidad
			
			if musica_nivel != null:
				musica_nivel.stream_paused = false # Volvemos a la normalidad
			# ----------------------------------------------------
	
# Esta es la función que llama el ítem del piso
func equipar_cuchillo() -> void:
	tiene_cuchillo = true
	# NO tocamos el GameManager acá para que si muere, 
	# el GameManager siga recordando que NO tenía cuchillo.
	actualizar_icono_cuchillo()
	$SonidoPoder.play()

var invulnerable: bool = false

func equipar_carrito() -> void:
	en_vehiculo = true
	actualizar_icono_carrito()
	# tiene_cuchillo = false <-- ESTA ES LA LÍNEA QUE HAY QUE BORRAR
	print("¡Chef motorizado!")
	
	# --- NUEVO: SONIDO DE POWER UP ---
	$SonidoPoder.play()
	# ---------------------------------

func equipar_sarten() -> void:
	tiempo_sarten = 20.0
	actualizar_icono_sarten()
	
	# --- SEGURIDAD DE AUDIO ---
	$SonidoPoder.process_mode = Node.PROCESS_MODE_ALWAYS
	$SonidoCarrito.process_mode = Node.PROCESS_MODE_ALWAYS # Esta es tu música de sartén
	
	# 1. Buscamos la música del nivel y la PAUSAMOS
	var musica_nivel = get_tree().current_scene.get_node_or_null("MusicaFondo")
	if musica_nivel != null:
		musica_nivel.stream_paused = true
	
	# 2. Le damos play a la música de la sartén
	$SonidoPoder.play()
	$SonidoCarrito.play()
	# --------------------------
	
	# (Acá sigue todo tu código del Jiggle y el Tween que ya tenías...)
	var posicion_atras = -30.0 * direccion_mirada
	var punto_inicio_global = global_position + Vector2(posicion_atras, -20.0)
	$PivoteSarten.global_position = punto_inicio_global
	
	$PivoteSarten.show() 
	$PivoteSarten/SartenOrbital/AnimatedSprite2D.play("Orbita")
	
	get_tree().paused = true
	var jiggle_tween = create_tween().set_loops(2).set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	# C. EL "BAILE" (Lento y Majestuoso)
	
	# JIGGLE X (Va a la izquierda, cruza a la derecha, vuelve al centro)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:x", -20.0, 0.4).set_trans(Tween.TRANS_SINE)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:x", 20.0, 0.7).set_trans(Tween.TRANS_SINE).set_delay(0.4)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:x", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_delay(1.1)

	# JIGGLE Y (Sube, baja, vuelve al centro)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:y", -15.0, 0.4).set_trans(Tween.TRANS_SINE)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:y", 15.0, 0.7).set_trans(Tween.TRANS_SINE).set_delay(0.4)
	jiggle_tween.tween_property($PivoteSarten/SartenOrbital, "position:y", 0.0, 0.4).set_trans(Tween.TRANS_SINE).set_delay(1.1)

	# D. PULSO DE TAMAÑO (Para que respire)
	# Crece durante 0.7 segundos y se achica durante 0.8 segundos
	jiggle_tween.tween_property($PivoteSarten, "scale", Vector2(1.3, 1.3), 0.7)
	jiggle_tween.tween_property($PivoteSarten, "scale", Vector2(1.0, 1.0), 0.8).set_delay(0.7)

	# --- E. ESPERAR Y ARRANCAR ---
	# Esperamos pacientemente a que termine sus 2 repeticiones (3 segundos en total)
	await jiggle_tween.finished 
	
	# Una vez que terminó, llamamos a la función manualmente
	start_pan_orbit()
	
func start_pan_orbit():
	get_tree().paused = false # Unpausamos el mundo
	# Reseteamos local position por si acaso
	$PivoteSarten/SartenOrbital.position = Vector2.ZERO
	
func actualizar_checkpoint(nueva_posicion: Vector2) -> void:
	var margen_derecha = 50 
	# Guardamos en la mochila global (GameManager)
	GameManager.checkpoint_pos = Vector2(nueva_posicion.x + margen_derecha, nueva_posicion.y)
	GameManager.checkpoint_camara_y = $Camera2D.global_position.y 
	
	# --- EL GUARDADO DEL ARMA (Manteniendo tu lógica) ---
	# Aquí es donde el cuchillo pasa de ser "temporal" a "guardado"
	GameManager.cuchillo_guardado = tiene_cuchillo
	# ----------------------------------------------------
	
	# Guardamos la "foto" de la energía actual
	GameManager.checkpoint_energia = GameManager.energia_actual
	
	# Guardamos si ya teníamos el plato al pisar la bandera
	GameManager.checkpoint_plato = GameManager.plato_recogido
	
	# --- EL ARREGLO DE LOS PUNTOS (Intacto) ---
	GameManager.puntos_confirmados += puntos_actuales_tramo
	puntos_actuales_tramo = 0
	# -------------------------------------------
	
	print("¡Checkpoint guardado! Cuchillo asegurado: ", GameManager.cuchillo_guardado)

func recibir_dano() -> void:
	# Si está titilando por haber perdido el carrito, no le pasa nada
	if invulnerable: 
		return
		
	# --- 1. EL ESCUDO DEL CARRITO ---
	if en_vehiculo:
		print("¡Escudo activado! El Chef pierde el carrito pero se salva.")
		en_vehiculo = false # Vuelve a estar a pie
		actualizar_icono_carrito()
		
		# --- NUEVO: SONIDO DE DESTRUCCIÓN DEL CARRITO ---
		if $SonidoDestruccionCarrito:
			$SonidoDestruccionCarrito.play()
		# -----------------------------------------------
		
		# Detenemos cualquier música que estuviera asociada al carrito (si quedó algo)
		$SonidoCarrito.stop()
		
		# --- APARECE EL HUMO ---
		if escena_humo != null:
			var nuevo_humo = escena_humo.instantiate()
			nuevo_humo.global_position = global_position
			get_tree().current_scene.add_child(nuevo_humo)
		
		# Lo hacemos titilar un ratito para que escape
		invulnerable = true
		var tween_escudo = create_tween()
		tween_escudo.set_loops(5)
		tween_escudo.tween_property($AnimatedSprite2D, "modulate:a", 0.0, 0.1)
		tween_escudo.tween_property($AnimatedSprite2D, "modulate:a", 1.0, 0.1)
		await tween_escudo.finished
		invulnerable = false
		
		return # Cortamos la función acá para que no muera
	# --------------------------------
		
	# --- 2. DAÑO NORMAL (A PIE) ---
	# Si el código llega hasta acá, es porque tocó un enemigo/trampa y no tenía carrito.
	# Va directo a la muerte por golpe (false = no fue por tiempo).
	procesar_muerte(false)

func actualizar_marcador():
	# Agarramos el puntaje total del GameManager + lo que llevamos ahora
	var puntos_totales = GameManager.puntos_confirmados + puntos_actuales_tramo
	
	# Lo transformamos en un texto de 6 números: ej "000150"
	var texto_puntos = str(puntos_totales).pad_zeros(6)
	
	# Obtenemos la lista de tus 6 sprites (A ESTA LÍNEA LE FALTABA EL TAB)
	var lista_de_sprites = get_parent().get_node("HUD/ColorRect/ContenedorPuntos").get_children()	
	
	# A cada sprite le decimos qué dibujo mostrar
	for i in range(6):
		var numero_a_mostrar = int(texto_puntos[i])
		lista_de_sprites[i].frame = numero_a_mostrar

func actualizar_relojes() -> void:
	# Ahora sí lo busca en el nivel principal, no adentro del Chef
	var contenedor_relojes = get_tree().current_scene.get_node_or_null("HUD/ColorRect/ContenedorRelojes")
	
	if contenedor_relojes == null:
		return
		
	# 3. Si SÍ existe, hacemos lo de siempre:
	var relojes = contenedor_relojes.get_children()
	
	# Revisamos uno por uno los 8 relojes
	for i in range(8):
		var reloj = relojes[i]
		
		# Cada reloj vale 4 puntos. Calculamos qué porción le toca a este.
		var limite_superior = (i + 1) * 4
		var limite_inferior = i * 4
		
		# Si la energía supera a este reloj, lo dibujamos LLENO
		if GameManager.energia_actual >= limite_superior:
			reloj.texture = img_reloj_4
			
		# Si la energía ni siquiera llega a este reloj, lo dibujamos VACÍO
		elif GameManager.energia_actual <= limite_inferior:
			reloj.texture = img_reloj_0
			
		# Si la energía cae JUSTO a la mitad de este reloj, calculamos el cuarto exacto
		else:
			var cuartos_sobrantes = GameManager.energia_actual - limite_inferior
			if cuartos_sobrantes == 3: reloj.texture = img_reloj_3
			elif cuartos_sobrantes == 2: reloj.texture = img_reloj_2
			elif cuartos_sobrantes == 1: reloj.texture = img_reloj_1
			
func actualizar_icono_cuchillo():
	# Buscamos el icono en el HUD (Asegurate de que la ruta sea la correcta según tu escena)
	var icono = get_parent().get_node("HUD/ColorRect/IconoCuchillo")
	
	if icono != null:
		if tiene_cuchillo == true:
			icono.texture = img_cuchillo_prendido
		else:
			icono.texture = img_cuchillo_apagado

func actualizar_icono_carrito():
	var icono = get_parent().get_node_or_null("HUD/ColorRect/IconoCarrito")
	if icono != null:
		if en_vehiculo == true:
			icono.texture = img_carrito_prendido
		else:
			icono.texture = img_carrito_apagado

func actualizar_icono_sarten():
	var icono = get_parent().get_node_or_null("HUD/ColorRect/IconoSarten")
	if icono != null:
		# La sartén está activa si le queda tiempo
		if tiempo_sarten > 0:
			icono.texture = img_sarten_prendida
		else:
			icono.texture = img_sarten_apagada

func actualizar_vidas():
	var lista_vidas = get_parent().get_node("HUD/ColorRect/ContenedorVidas").get_children()
	
	for i in range(3):
		if i < GameManager.vidas_actuales:
			lista_vidas[i].show() # Muestra el gorrito
		else:
			lista_vidas[i].hide() # Oculta el gorrito
			
func sumar_puntos(puntos_nuevos: int) -> void:
	# 1. Guardamos los puntos en la memoria global (¡con el += para que se acumulen!)
	GameManager.puntos_confirmados += puntos_nuevos
	
	# 2. Actualizamos el HUD del nivel para que lo veas mientras jugás
	actualizar_marcador() # (Poné acá la función exacta que tenías antes para el HUD)

# --- NUEVA FUNCIÓN MAESTRA DE MUERTE ---
# Le agregamos un "aviso" entre paréntesis para saber de qué murió
func procesar_muerte(murio_por_tiempo: bool = false):
	# 1. SEGURIDAD: Si el Chef ya no está en el juego, no hacemos nada
	if not is_inside_tree():
		return

	GameManager.vidas_actuales -= 1
	
	if GameManager.vidas_actuales > 0:
		print("¡Perdiste una vida! Quedan: ", GameManager.vidas_actuales)
		
		if murio_por_tiempo == true:
			GameManager.energia_actual = GameManager.energia_maxima 
		else:
			GameManager.energia_actual = GameManager.checkpoint_energia
		
		GameManager.plato_recogido = GameManager.checkpoint_plato
		
		# --- NUEVO: CASTIGO DE PUNTOS ---
		# Revertimos los puntos a lo que teníamos en el último checkpoint
		GameManager.puntos_confirmados = GameManager.checkpoint_puntos
		# --------------------------------
		
		# 2. ESPERA SEGURA: Esperamos un frame para que todo se asiente
		await get_tree().process_frame
		
		# 3. ÚLTIMO CHEQUEO: Antes de recargar, verificamos que el árbol exista
		if get_tree() != null:
			get_tree().reload_current_scene()
		
	else:
		print("¡GAME OVER - PASANDO POR PANTALLA BONUS!")
		GameManager.nivel_superado = false
		GameManager.puntos_confirmados += puntos_actuales_tramo
		
		# --- LIMPIEZA TOTAL PARA LA PRÓXIMA PARTIDA ---
		GameManager.vidas_actuales = 3
		GameManager.energia_actual = GameManager.energia_maxima
		GameManager.checkpoint_pos = Vector2.ZERO
		GameManager.sombrero_recogido = false
		
		# ¡ESTO ES LO QUE TE FALTA!
		GameManager.cuchillo_guardado = false 
		GameManager.trajo_cuchillo = false
		# ----------------------------------------------
		
		await get_tree().process_frame
		if get_tree() != null:
			get_tree().change_scene_to_file("res://pantalla_bonus.tscn")

func morir_por_caida() -> void:
	# Evitamos llamar a la muerte si ya estamos en proceso de morir
	if not is_inside_tree(): 
		return
		
	print("¡El Chef cayó al vacío!")
	procesar_muerte(false)
