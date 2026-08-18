extends CharacterBody2D

# 1. Declare o Sprite E as colisões no topo
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var forma_em_pe: CollisionShape2D = $FormaEmPe
@onready var forma_no_ar: CollisionShape2D = $FormaNoAr

const SPEED = 300.0
const JUMP_VELOCITY = -300.0

func _physics_process(delta: float) -> void:
	# 2. Mantém a gravidade funcionando
	if not is_on_floor():
		velocity += get_gravity() * delta

	# 3. Alterna qual colisão está ativa
	forma_em_pe.set_deferred("disabled", not is_on_floor())
	forma_no_ar.set_deferred("disabled", is_on_floor())

	# 4. Pulo
	if Input.is_action_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 5. Leitura do movimento
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# 6. Troca de animações (Usando a variável 'sprite')
	if is_on_floor():
		if direction > 0:
			sprite.flip_h = false
			sprite.play("walk")
		elif direction < 0:
			sprite.flip_h = true
			sprite.play("walk")
		else:
			sprite.play("idle")
	else:
		sprite.play("jump")

	move_and_slide()
