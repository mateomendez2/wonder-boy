extends Control

@export var nodo_plato: TextureRect
@export var imagen_color: Texture2D
@export var imagen_sombra: Texture2D

var puede_continuar: bool = false

func _ready() -> void:
	# 0. Escondemos el texto apenas arranca
	$Label.hide()

	# --- NUEVO: GESTIÓN DE AUDIO AL LLEGAR ---
	if GameManager.nivel_superado == false:
		# Si llegamos acá por muerte, hacemos sonar el Game Over
		GameManager.reproducir_sonido_game_over()
	# -----------------------------------------

	# --- 1. LÓGICA DEL PLATO (IMÁGENES) ---
	if nodo_plato != null:
		nodo_plato.modulate = Color.WHITE 
		if GameManager.plato_recogido == true:
			nodo_plato.texture = imagen_color
		else:
			nodo_plato.texture = imagen_sombra
			
	# --- 2. LÓGICA DEL PUNTAJE ---
	arrancar_conteo(GameManager.puntos_confirmados)
	
	# --- 3. EL BOOTEO ARCADE ---
	# Esperamos a que termine la ruleta
	await get_tree().create_timer(2.5).timeout
	
	# ¡Acá adentro activamos el texto! (Fijate que tiene sangría)
	$Label.show()
	hacer_que_titile()
	puede_continuar = true

func _process(_delta: float) -> void:
	# Si el candado está abierto y aprieta Enter o Espacio
	if puede_continuar and Input.is_action_just_pressed("ui_accept"):
		cambiar_de_escena()

func cambiar_de_escena():
	puede_continuar = false
	
	# --- NUEVO: APAGAR LA MÚSICA DE VICTORIA Y DERROTA ---
	# Esto detiene cualquier canción que venga sonando
	# para que no se mezcle con el siguiente nivel o el inicio.
	GameManager.detener_musica_victoria()
	GameManager.detener_sonido_game_over()
	# --------------------------------------------
	
	if GameManager.nivel_superado == true:
		
		# --- ¿VENIMOS DEL NIVEL 1? ---
		if GameManager.nivel_actual == 1:
			print("Cargando Nivel 2...")
			
			# --- NUEVO: GUARDAMOS Y VACIAMOS LOS PUNTOS ---
			GameManager.puntaje_acumulado += GameManager.puntos_confirmados
			GameManager.puntos_confirmados = 0
			GameManager.checkpoint_puntos = 0
			# ----------------------------------------------
			
			GameManager.trajo_cuchillo = GameManager.cuchillo_guardado
			GameManager.checkpoint_pos = Vector2.ZERO 
			GameManager.plato_recogido = false
			GameManager.nivel_superado = false
			
			get_tree().change_scene_to_file("res://nivel_2.tscn")
			
		# --- ¿VENIMOS DEL NIVEL 2? ---
		elif GameManager.nivel_actual == 2:
			print("¡Juego Terminado! Cargando Pantalla Final...")
			
			# --- NUEVO: GUARDAMOS EL NIVEL 2 EN EL TOTAL ---
			GameManager.puntaje_acumulado += GameManager.puntos_confirmados
			# -----------------------------------------------
			
			get_tree().change_scene_to_file("res://pantalla_final.tscn")
			
	else:
		# --- GAME OVER ---
		print("Volviendo al inicio por Game Over...")
		get_tree().change_scene_to_file("res://pantalla_inicio.tscn")
		GameManager.puntos_confirmados = 0
		GameManager.plato_recogido = false
		GameManager.nivel_superado = false
		GameManager.nivel_actual = 1

# --- NUESTRO NUEVO PLAN B (SIN NODO TIMER) ---
func hacer_que_titile():
	var tween = create_tween().set_loops()
	tween.tween_property($Label, "modulate:a", 0.0, 0.5) 
	tween.tween_property($Label, "modulate:a", 1.0, 0.5) 

# --- LA ANIMACIÓN DEL CONTEO ---
func arrancar_conteo(puntaje_final: int) -> void:
	var tween = create_tween()
	tween.tween_method(actualizar_marcador, 0, puntaje_final, 2.0)

# --- EL CEREBRO DE LOS NÚMEROS ---
func actualizar_marcador(valor: int) -> void:
	var texto_puntaje = str(valor).pad_zeros(6)
	
	$ContadorRound/Digito1.frame = int(texto_puntaje[0])
	$ContadorRound/Digito2.frame = int(texto_puntaje[1])
	$ContadorRound/Digito3.frame = int(texto_puntaje[2])
	$ContadorRound/Digito4.frame = int(texto_puntaje[3])
	$ContadorRound/Digito5.frame = int(texto_puntaje[4])
	$ContadorRound/Digito6.frame = int(texto_puntaje[5])
