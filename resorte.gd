extends Area2D

@export var fuerza_salto: float = -900.0 
@export var imagen_estirado: Texture2D 
var imagen_original: Texture2D 

func _ready() -> void:
	imagen_original = $Sprite2D.texture

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# --- 1. EL SALTO Y SONIDO (AL TOQUE) ---
		# Hacemos esto primero para que no haya ni un frame de retraso
		body.velocity.y = fuerza_salto
		$SonidoResorte.play()
		
		# --- 2. EFECTO VISUAL (SIN BLOQUEAR) ---
		if imagen_estirado != null:
			$Sprite2D.texture = imagen_estirado
			
			# Llamamos a una función aparte para que el 'await' 
			# no frene este bloque de código
			volver_a_original()

func volver_a_original() -> void:
	# Espera 0.2 segundos y resetea la imagen
	await get_tree().create_timer(0.1).timeout
	$Sprite2D.texture = imagen_original
