extends RigidBody2D

var direccion_vuelo: int = 1
var activo_para_chocar: bool = false

func _ready() -> void:
	# 1. Orientación visual (lo que vimos antes)
	$Sprite2D.flip_h = (direccion_vuelo == 1)
	
	# 2. Impulso inicial
	apply_central_impulse(Vector2(300 * direccion_vuelo, -150))
	
	# 3. Rotación estética (para que gire en el aire)
	angular_velocity = 15 * direccion_vuelo 
	
	# 4. Tiempo de seguridad antes de activar colisiones
	await get_tree().create_timer(0.05).timeout
	activo_para_chocar = true

# --- ESTA ES LA FUNCIÓN DEL PASO 4 ---
func _on_body_entered(body: Node) -> void:
	if not activo_para_chocar:
		return

	# A. ¿Chocó contra un enemigo?
	if body.has_method("morir"):
		body.morir()   # Ejecuta la función morir del enemigo
		queue_free()   # El cuchillo desaparece
		
	# B. ¿Chocó contra el escenario (pasto, castillo, paredes, lo que sea)?
	# Si con lo que chocó NO es el Chef, asumimos que es el mundo y se destruye.
	elif body.name != "Chef":
		queue_free()
