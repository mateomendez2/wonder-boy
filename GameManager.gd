extends Node

# --- MEMORIA GLOBAL ---
var checkpoint_pos: Vector2 = Vector2.ZERO
var checkpoint_camara_y: float = 0.0
var puntos_confirmados: int = 0 
var checkpoint_puntos: int = 0
var puntaje_acumulado: int = 0
var cuchillo_guardado: bool = false
var trajo_cuchillo: bool = false 
var plato_recogido: bool = false

var nivel_actual: int = 1
var nivel_superado: bool = false
var vidas_actuales: int = 3

# --- VARIABLES DE ENERGÍA Y ESTADO ---
var energia_maxima: int = 32 # 8 relojes x 4 cuartos cada uno
var energia_actual: int = 32
var checkpoint_energia: int = 32

var sombrero_recogido: bool = false
var checkpoint_plato: bool = false

# --- REPRODUCTORES DE AUDIO ---
var reproductor_victoria = AudioStreamPlayer.new()
var reproductor_game_over = AudioStreamPlayer.new() 
var reproductor_final = AudioStreamPlayer.new() # Nuestro reproductor final

func _ready() -> void:
	# Agregamos los reproductores como hijos del GameManager
	add_child(reproductor_victoria)
	add_child(reproductor_game_over)
	add_child(reproductor_final)
	
	# CARGAMOS LOS ARCHIVOS
	reproductor_victoria.stream = load("res://MusicaNivelTerminado.ogg")
	reproductor_game_over.stream = load("res://SonidoGameOver.wav") 
	reproductor_final.stream = load("res://MusicaFinal.ogg")
	
	# Desactivamos el loop asignando el bus Master
	reproductor_victoria.bus = "Master" 
	reproductor_game_over.bus = "Master" 
	reproductor_final.bus = "Master"
	
	print("GameManager: Sistemas de audio de victoria, derrota y final listos")

# --- FUNCIONES DE VICTORIA ---
func reproducir_musica_victoria():
	if reproductor_victoria.stream != null:
		reproductor_victoria.play()

func detener_musica_victoria():
	reproductor_victoria.stop()

# --- FUNCIONES DE GAME OVER ---
func reproducir_sonido_game_over():
	if reproductor_game_over.stream != null:
		reproductor_game_over.play()

func detener_sonido_game_over():
	reproductor_game_over.stop()

# --- FUNCIONES DE MÚSICA FINAL (NUEVAS) ---
func reproducir_musica_final():
	if reproductor_final.stream != null:
		reproductor_final.play()

func detener_musica_final():
	reproductor_final.stop()

# --- FUNCIÓN DE RESET MAESTRA ---
func reiniciar_todo():
	checkpoint_pos = Vector2.ZERO
	checkpoint_camara_y = 0.0
	puntos_confirmados = 0
	checkpoint_puntos = 0
	puntaje_acumulado = 0
	
	# Reset de armas
	cuchillo_guardado = false
	trajo_cuchillo = false
	
	# Reset de items y salud
	energia_actual = energia_maxima
	checkpoint_energia = energia_maxima
	vidas_actuales = 3
	sombrero_recogido = false
	plato_recogido = false
	checkpoint_plato = false
	
	# Por seguridad apagamos cualquier sonido que haya quedado colgado
	detener_musica_victoria()
	detener_sonido_game_over()
	detener_musica_final() # <--- También apagamos la música final al reiniciar
	
	print("GameManager: Memoria reseteada por completo")
