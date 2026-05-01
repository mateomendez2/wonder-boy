extends RigidBody2D

var velocidad_maxima: float = 70.0 # Ajustá este número a tu gusto

func _physics_process(delta: float) -> void:
	# Limitamos la velocidad horizontal de la roca. 
	# Clamp le dice: "Tu velocidad puede ser la que quieras, pero NUNCA menor a -150 ni mayor a 150"
	linear_velocity.x = clamp(linear_velocity.x, -velocidad_maxima, velocidad_maxima)
	
func _on_hurtbox_body_entered(body: Node2D) -> void:
	# Usamos "chef" en minúscula como lo tenés vos
	if body.name == "Chef":
		add_collision_exception_with(body)
		body.recibir_dano()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()

func _on_radar_body_entered(body: Node2D) -> void:
	if body.name == "Chef":
		# 1. Le devolvemos la gravedad para que empiece a caer
		gravity_scale = 2.5
	 
		
		# 2. Le damos una fuerte "patada" física hacia la derecha (o izquierda si le ponés -300)
		# Esto asegura que rompa cualquier inercia y empiece a rodar
		apply_central_impulse(Vector2(300, 0)) 
		
		# 3. Borramos el radar
		$Radar.queue_free()
