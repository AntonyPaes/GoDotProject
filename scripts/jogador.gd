extends CharacterBody2D


enum PlayerState {
	IDLE,
	WALK,
	JUMP,
	HURT,
	ATTACK,
	DEATH
}


var status: PlayerState = PlayerState.IDLE


@export var vida_maxima: int = 5
@export var tempo_hurt: float = 0.4
@export var dano_do_golpe: int = 2
@export var quadro_do_golpe: int = 3


const SPEED := 150.0
const JUMP_VELOCITY := -400.0


var vida: int = 0
var tempo_no_hurt: float = 0.0
var golpe_aplicado: bool = false


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_golpe: Area2D = get_node_or_null("AreaGolpe")


func _ready() -> void:
	vida = vida_maxima
	go_to_idle_state()


func _physics_process(delta: float) -> void:

	# Gravidade
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:

		PlayerState.IDLE:
			idle_state()

		PlayerState.WALK:
			walk_state()

		PlayerState.JUMP:
			jump_state()

		PlayerState.HURT:
			hurt_state()

		PlayerState.ATTACK:
			attack_state()

		PlayerState.DEATH:
			pass

	move_and_slide()


# =========================================================
# IDLE
# =========================================================

func go_to_idle_state() -> void:
	status = PlayerState.IDLE
	velocity.x = 0

	anim.play("idle")
	anim.modulate = Color.WHITE


func idle_state() -> void:

	# Ataque
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()
		return

	var direction := Input.get_axis("ui_left", "ui_right")

	# Andar
	if direction != 0:
		go_to_walk_state()
		return

	velocity.x = move_toward(velocity.x, 0, SPEED)


# =========================================================
# WALK
# =========================================================

func go_to_walk_state() -> void:
	status = PlayerState.WALK
	anim.play("walk")


func walk_state() -> void:

	var direction := Input.get_axis("ui_left", "ui_right")

	# Parou de andar
	if direction == 0:
		go_to_idle_state()
		return

	# Pulo
	if Input.is_action_just_pressed("jump") and is_on_floor():
		go_to_jump_state()
		return

	# Ataque
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

	velocity.x = direction * SPEED

	atualizar_direcao(direction)


# =========================================================
# JUMP
# =========================================================

func go_to_jump_state() -> void:
	status = PlayerState.JUMP

	velocity.y = JUMP_VELOCITY

	anim.play("jump")


func jump_state() -> void:

	var direction := Input.get_axis("ui_left", "ui_right")

	# Controle horizontal no ar
	if direction != 0:
		velocity.x = direction * SPEED
		atualizar_direcao(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Ataque no ar
	if Input.is_action_just_pressed("attack"):
		go_to_attack_state()
		return

	# Voltou ao chão
	if is_on_floor():

		if direction != 0:
			go_to_walk_state()
		else:
			go_to_idle_state()

		return


# =========================================================
# HURT
# =========================================================

func go_to_hurt_state() -> void:
	status = PlayerState.HURT

	velocity.x = 0

	tempo_no_hurt = 0.0

	anim.play("hurt")

	anim.modulate = Color(1.0, 0.4, 0.4)

	if area_golpe != null:
		area_golpe.set_deferred("monitoring", false)


func hurt_state() -> void:

	tempo_no_hurt += get_physics_process_delta_time()

	if tempo_no_hurt >= tempo_hurt:

		go_to_idle_state()

		return


# =========================================================
# ATAQUE
# =========================================================

func go_to_attack_state() -> void:
	status = PlayerState.ATTACK

	velocity.x = 0

	golpe_aplicado = false

	anim.play("attack")

	if area_golpe != null:
		area_golpe.monitoring = true


func attack_state() -> void:

	if area_golpe == null:

		if not anim.is_playing():
			go_to_idle_state()

		return

	# Momento em que o golpe realmente acerta
	if not golpe_aplicado and anim.frame >= quadro_do_golpe:

		golpe_aplicado = true

		for corpo in area_golpe.get_overlapping_bodies():

			if corpo == self:
				continue

			if corpo.has_method("levar_dano"):
				corpo.levar_dano(dano_do_golpe)

	# Terminou a animação
	if not anim.is_playing():

		area_golpe.set_deferred("monitoring", false)

		go_to_idle_state()

		return


# =========================================================
# RECEBER DANO
# =========================================================

func levar_dano(quantidade: int) -> void:
	print("DANO RECEBIDO PELO JOGADOR: ", quantidade)

	if status == PlayerState.HURT:
		return

	if status == PlayerState.DEATH:
		return

	vida -= quantidade

	print("VIDA DO JOGADOR: ", vida)

	if vida <= 0:
		morrer()
		return

	go_to_hurt_state()


# =========================================================
# MORTE
# =========================================================

func morrer() -> void:

	status = PlayerState.DEATH

	velocity.x = 0

	anim.play("death")

	if area_golpe != null:
		area_golpe.set_deferred("monitoring", false)

	set_physics_process(false)


# =========================================================
# DIREÇÃO
# =========================================================

func atualizar_direcao(direction: float) -> void:

	if direction > 0:

		anim.flip_h = false

		if area_golpe != null:
			area_golpe.position.x = abs(area_golpe.position.x)

	elif direction < 0:

		anim.flip_h = true

		if area_golpe != null:
			area_golpe.position.x = -abs(area_golpe.position.x)
