extends Control

const RUTA_NIVEL = "res://nivel_1.tscn" 
var progreso = []
var carga_terminada = false
var puede_entrar = false # <--- NUEVO CANDADO

func _ready() -> void:
	$LabelStart.hide()
	
	var tween_logo = create_tween().set_loops()
	var pos_original = $TextureRect2.position.y 
	tween_logo.tween_property($TextureRect2, "position:y", pos_original - 10, 1.3).set_trans(Tween.TRANS_SINE)
	tween_logo.tween_property($TextureRect2, "position:y", pos_original, 1.3).set_trans(Tween.TRANS_SINE)
	
	ResourceLoader.load_threaded_request(RUTA_NIVEL)

func _process(_delta: float) -> void:
	# --- 1. CUANDO YA ESTÁ TODO LISTO Y HABILITADO ---
	if puede_entrar:
		if Input.is_action_just_pressed("ui_accept"):
			puede_entrar = false 
			
			# --- ¡LA CLAVE DEL RESET! ---
			# Limpiamos la mochila global antes de entrar al nivel
			GameManager.reiniciar_todo() 
			# ----------------------------
			
			$LabelStart/Timer.stop()
			$LabelStart.hide()
			
			$SonidoStart.play()
			await $SonidoStart.finished
			
			var escena_cargada = ResourceLoader.load_threaded_get(RUTA_NIVEL)
			get_tree().change_scene_to_packed(escena_cargada)
			
		return
		
	# --- 2. EL PROCESO DE CARGA INVISIBLE ---
	if not carga_terminada:
		var estado = ResourceLoader.load_threaded_get_status(RUTA_NIVEL, progreso)
		if estado == ResourceLoader.THREAD_LOAD_LOADED:
			carga_terminada = true
			preparar_entrada()

# --- EL BOOTEO ARCADE ---
func preparar_entrada() -> void:
	# Le clavamos 2 segundos de espera a propósito para que se estabilice
	await get_tree().create_timer(2.0).timeout
	
	# Ahora sí, mostramos el texto y habilitamos el botón
	$LabelStart.show()
	$LabelStart/Timer.start() 
	puede_entrar = true
	$LabelStart.visible = not $LabelStart.visible

# Esta función hace que el texto titile cada vez que el Timer da la vuelta
func _on_timer_timeout() -> void:
	$LabelStart.visible = not $LabelStart.visible
