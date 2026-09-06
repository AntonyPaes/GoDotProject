extends CharacterBody2D


enum State {
	IDLE,
	WALK,
	JUMP,
	CROUCH
}


var state: State = State.IDLE

const SPEED := 250.0
const JUMP_VELOCITY := -300.0
const MAX_JUMPS := 2

const NORMAL_COLLIDER_SCALE := Vector2(1.0, 1.0)
const CROUCH_COLLIDER_SCALE := Vector2(1.0, 0.6)

const NORMAL_SPRITE_SCALE := Vector2(1.0, 1.0)
const CROUCH_SPRITE_SCALE := Vector2(1.0, 0.65)

const NORMAL_SPRITE_POSITION := Vector2(0, -2)
const CROUCH_SPRITE_POSITION := Vector2(0, 1)


var jump_count := 0


@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var forma_em_pe: CollisionShape2D = $FormaEmPe
@onready var forma_no_ar: CollisionShape2D = $FormaNoAr


func _ready() -> void:
	go_to_idle()


func _physics_process(delta: float) -> void:
	# Se está no chão, o contador de pulos volta para zero.
	if is_on_floor():
		jump_count = 0

	# Gravidade.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Direção horizontal.
	var direction := Input.get_axis("ui_left", "ui_right")

	# Máquina de estados.
	match state:
		State.IDLE:
			state_idle(direction)

		State.WALK:
			state_walk(direction)

		State.JUMP:
			state_jump(direction)

		State.CROUCH:
			state_crouch()

	# Movimento físico.
	move_and_slide()

	# Quando termina o pulo e encosta no chão,
	# volta para parado ou andando.
	if state == State.JUMP and is_on_floor():
		if direction != 0:
			go_to_walk()
			return

		go_to_idle()
		return


# ============================================================
# ESTADO IDLE
# ============================================================

func go_to_idle() -> void:
	state = State.IDLE

	forma_em_pe.set_deferred("disabled", false)
	forma_em_pe.set_deferred("scale", NORMAL_COLLIDER_SCALE)

	sprite.scale = NORMAL_SPRITE_SCALE
	sprite.position = NORMAL_SPRITE_POSITION
	sprite.play("idle")

func state_idle(direction: float) -> void:
	velocity.x = move_toward(velocity.x, 0, SPEED)

	if Input.is_action_pressed("crouch"):
		go_to_crouch()
		return

	if Input.is_action_just_pressed("ui_accept"):
		jump_count = 1
		velocity.y = JUMP_VELOCITY
		go_to_jump()
		return

	if direction != 0:
		go_to_walk()
		return


# ============================================================
# ESTADO WALK
# ============================================================

func go_to_walk() -> void:
	state = State.WALK

	forma_em_pe.set_deferred("disabled", false)
	forma_em_pe.set_deferred("scale", NORMAL_COLLIDER_SCALE)

	sprite.scale = NORMAL_SPRITE_SCALE
	sprite.position = NORMAL_SPRITE_POSITION
	sprite.play("walk")


func state_walk(direction: float) -> void:
	if not is_on_floor():
		jump_count = 1
		go_to_jump()
		return

	if Input.is_action_pressed("crouch"):
		go_to_idle()
		return

	if Input.is_action_just_pressed("ui_accept"):
		jump_count = 1
		velocity.y = JUMP_VELOCITY
		go_to_jump()
		return

	if direction == 0:
		go_to_idle()
		return

	velocity.x = direction * SPEED

	update_facing(direction)


# ============================================================
# ESTADO JUMP
# ============================================================

func go_to_jump() -> void:
	state = State.JUMP

	sprite.scale = NORMAL_SPRITE_SCALE
	sprite.position = NORMAL_SPRITE_POSITION
	sprite.play("jump")


func state_jump(direction: float) -> void:
	velocity.x = direction * SPEED

	if direction != 0:
		update_facing(direction)

	# Segundo pulo.
	if Input.is_action_just_pressed("ui_accept"):
		if jump_count < MAX_JUMPS:
			jump_count += 1
			velocity.y = JUMP_VELOCITY
			return


# ============================================================
# ESTADO CROUCH
# ============================================================

func go_to_crouch() -> void:
	state = State.CROUCH

	forma_em_pe.set_deferred("disabled", false)
	forma_em_pe.set_deferred("scale", CROUCH_COLLIDER_SCALE)

	sprite.scale = NORMAL_SPRITE_SCALE
	sprite.position = NORMAL_SPRITE_POSITION
	sprite.play("crouch")

func state_crouch() -> void:
	velocity.x = 0

	if not Input.is_action_pressed("crouch"):
		go_to_idle()
		return

	# A tecla precisa continuar segurada.
	if not Input.is_action_pressed("crouch"):
		go_to_idle()
		return


# ============================================================
# UTILITÁRIO
# ============================================================

func update_facing(direction: float) -> void:
	if direction > 0:
		sprite.flip_h = false

	elif direction < 0:
		sprite.flip_h = true
