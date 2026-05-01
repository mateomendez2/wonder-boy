extends Control

var puede_continuar: bool = false
var puntaje_final: int = 0

func _ready() -> void:
	# --- MÚSICA DE CRÉDITOS/FINAL ---
	GameManager.reproducir_musica_final()

	# 1. Ocultar cosas iniciales
	$Label.hide()
	
	# 2. Leer el puntaje que acumulaste (AHORA LEE EL TOTAL DE LOS 2 NIVELES)
	puntaje_final = GameManager.puntaje_acumulado
	
	# 3. Arrancar la secuencia cinematográfica
	animar_entrada()

func animar_entrada() -> void:
	# Guardamos las posiciones Y originales para que reboten justo a donde las pusiste
	var pos_original_score = $CartelScore.position.y
	var pos_original_total = $CartelTotal.position.y
	
	# Los movemos 50 píxeles para arriba y los hacemos transparentes para empezar
	$CartelScore.position.y -= 50
	$CartelTotal.position.y -= 50
	$CartelScore.modulate.a = 0.0
	$CartelTotal.modulate.a = 0.0
	
	# Dejamos los números en "000000" para empezar limpios
	actualizar_marcador(0)
	
	# -- ANIMACIÓN 1: Cae la palabra SCORE con rebote --
	var tween_score = create_tween().set_parallel(true)
	# Trans_bounce hace que rebote como una pelota al llegar a su lugar
	tween_score.tween_property($CartelScore, "position:y", pos_original_score, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_score.tween_property($CartelScore, "modulate:a", 1.0, 0.4)
	
	await tween_score.finished # Esperamos a que termine
	
	# -- ANIMACIÓN 2: Cae la palabra TOTAL con rebote --
	var tween_total = create_tween().set_parallel(true)
	tween_total.tween_property($CartelTotal, "position:y", pos_original_total, 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween_total.tween_property($CartelTotal, "modulate:a", 1.0, 0.4)
	
	await tween_total.finished
	
	# Damos un respiro mínimo de medio segundo de suspenso...
	await get_tree().create_timer(0.5).timeout
	
	# -- ANIMACIÓN 3: Arranca la ruleta de números --
	arrancar_conteo()

func arrancar_conteo() -> void:
	var tween = create_tween()
	# ¡Reciclamos tu propio código! De 0 al puntaje en 2 segundos
	tween.tween_method(actualizar_marcador, 0, puntaje_final, 2.0)
	await tween.finished
	
	# -- FINAL: Mostramos el "Press Enter" y habilitamos para volver --
	$Label.show()
	hacer_que_titile()
	puede_continuar = true

func actualizar_marcador(valor: int) -> void:
	# Transforma el número en un texto de 6 dígitos con ceros a la izquierda (ej: 001500)
	var texto_puntaje = str(valor).pad_zeros(6)
	var sprites = $NumerosTotal.get_children()
	
	# Le asignamos a cada sprite tu dibujo correspondiente
	for i in range(sprites.size()):
		sprites[i].frame = int(texto_puntaje[i])

func hacer_que_titile():
	# Tu código original para que parpadee el "Press Enter"
	var tween = create_tween().set_loops()
	tween.tween_property($Label, "modulate:a", 0.0, 0.5) 
	tween.tween_property($Label, "modulate:a", 1.0, 0.5) 

func _input(event: InputEvent) -> void:
	# Si ya terminó toda la animación y el jugador presiona Enter...
	if puede_continuar and event.is_action_pressed("ui_accept"):
		
		# ¡Reseteo total para dejar el juego limpio por si quieren volver a jugar!
		# Al llamar a reiniciar_todo() acá, la música final se va a apagar sola.
		GameManager.reiniciar_todo()
		
		GameManager.nivel_actual = 1
		GameManager.vidas_actuales = 3
		GameManager.plato_recogido = false
		GameManager.nivel_superado = false
		GameManager.cuchillo_guardado = false
		GameManager.trajo_cuchillo = false
		GameManager.sombrero_recogido = false
		GameManager.checkpoint_plato = false
		
		# Viajamos de vuelta al menú inicial
		get_tree().change_scene_to_file("res://pantalla_inicio.tscn")
