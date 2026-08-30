extends CharacterBody2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

const SPEED := 200.0
const JUMP_VELOCITY := -300.0


func _physics_process(delta: float) -> void:
	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Movimento horizontal
	var direction := Input.get_axis("ui_left", "ui_right")

	if direction != 0:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Animações
	if not is_on_floor():
		sprite.play("jump")
	elif direction != 0:
		sprite.play("walk")
		sprite.flip_h = direction < 0
	else:
		sprite.play("idle")

	move_and_slide()
