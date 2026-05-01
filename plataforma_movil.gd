extends AnimatableBody2D

# Podés cambiar estos números desde el Inspector de la derecha
@export var distancia_y: float = -50.0 # Cuánto sube (negativo es para arriba)
@export var tiempo_viaje: float = 2.0   # Segundos que tarda en ir de un lado a otro

var posicion_inicial: float

func _ready() -> void:
	# Guardamos dónde la pusiste en el mapa para usarlo como punto de anclaje
	posicion_inicial = global_position.y
	
	# Arrancamos el motor
	iniciar_ascensor()

func iniciar_ascensor() -> void:
	# Creamos un Tween infinito
	# IMPORTANTE: set_process_mode(Tween.TWEEN_PROCESS_PHYSICS) hace que 
	# se mueva al mismo ritmo que las físicas del Chef, evitando tirones.
	var tween = create_tween().set_loops().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	
	# 1. Viaje de IDA (Sube)
	tween.tween_property(self, "global_position:y", posicion_inicial + distancia_y, tiempo_viaje).set_trans(Tween.TRANS_SINE)
	
	# 2. Viaje de VUELTA (Baja a su posición original)
	tween.tween_property(self, "global_position:y", posicion_inicial, tiempo_viaje).set_trans(Tween.TRANS_SINE)
