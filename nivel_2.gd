extends Node2D

func _ready() -> void:
	# 1. Le recargamos la energía al 100% (el reloj vuelve a tope para el Nivel 2)
	GameManager.energia_actual = GameManager.energia_maxima
	# (Le sumamos esto por si muere, para que reviva con el reloj lleno)
	GameManager.checkpoint_energia = GameManager.energia_maxima 

	# 3. Le avisamos al cerebro que estamos jugando el segundo nivel
	GameManager.nivel_actual = 2
