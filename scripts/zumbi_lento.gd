extends CharacterBody2D


enum ZumbiState {
	idle,
	chase,
	attack,
	hurt,
	death
}


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var area_ataque: Area2D = $AreaAtaque


@export var vida_maxima: int = 4
@export var velocidade: float = 35.0
@export var dano: int = 1
@export var distancia_de_ataque: float = 60.0
@export var distancia_de_visao: float = 130.0
@export var animacao_de_andar: String = "walk"
@export var tempo_entre_ataques: float = 1.2
@export var tempo_hurt: float = 0.25
@export var quadro_do_golpe: int = 4


var tempo_no_hurt: float = 0.0
var vida: int = 0
var status: ZumbiState = ZumbiState.idle
var tempo_do_ataque: float = 0.0
var golpe_aplicado: bool = false


func _ready() -> void:
	vida = vida_maxima
	area_ataque.monitoring = false
	go_to_idle_state()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		ZumbiState.idle:
			idle_state()

		ZumbiState.chase:
			chase_state()

		ZumbiState.attack:
			attack_state()

		ZumbiState.hurt:
			hurt_state()

		ZumbiState.death:
			pass

	move_and_slide()


func alvo() -> Node2D:
	var jogador = get_tree().get_first_node_in_group("player")
	print("ALVO ENCONTRADO: ", jogador)
	return jogador


func go_to_idle_state() -> void:
	status = ZumbiState.idle
	anim.play("idle")
	velocity.x = 0


func idle_state() -> void:
	var p := alvo()

	if p == null:
		return

	if global_position.distance_to(p.global_position) <= distancia_de_visao:
		go_to_chase_state()
		return


func go_to_chase_state() -> void:
	status = ZumbiState.chase
	anim.play(animacao_de_andar)


func chase_state() -> void:
	var p := alvo()

	if p == null:
		go_to_idle_state()
		return

	var distancia := global_position.distance_to(p.global_position)

	if distancia > distancia_de_visao:
		go_to_idle_state()
		return

	if distancia <= distancia_de_ataque:
		go_to_attack_state()
		return

	var lado := signf(p.global_position.x - global_position.x)

	velocity.x = lado * velocidade

	olhar_para(lado)


func olhar_para(lado: float) -> void:
	if lado == 0:
		return

	anim.flip_h = lado < 0

	area_ataque.position.x = abs(area_ataque.position.x) * lado


func go_to_attack_state() -> void:
	status = ZumbiState.attack

	anim.play("attack")

	velocity.x = 0

	tempo_do_ataque = 0.0
	golpe_aplicado = false

	var p := alvo()

	if p != null:
		var lado := signf(p.global_position.x - global_position.x)
		olhar_para(lado)

	area_ataque.monitoring = true


func attack_state() -> void:
	tempo_do_ataque += get_physics_process_delta_time()

	if not golpe_aplicado and anim.frame >= quadro_do_golpe:
		golpe_aplicado = true

		for corpo in area_ataque.get_overlapping_bodies():

			if corpo == self:
				continue

			if corpo.is_in_group("player") and corpo.has_method("levar_dano"):
				corpo.levar_dano(dano)

	if tempo_do_ataque >= tempo_entre_ataques:
		area_ataque.monitoring = false

		var p := alvo()

		if p != null and global_position.distance_to(p.global_position) <= distancia_de_ataque:
			go_to_attack_state()
		else:
			go_to_chase_state()

		return


func levar_dano(quantidade: int) -> void:
	if status == ZumbiState.death:
		return

	if status == ZumbiState.hurt:
		return

	vida -= quantidade

	print("Zumbi recebeu dano. Vida: ", vida)

	if vida <= 0:
		go_to_death_state()
		return

	go_to_hurt_state()


func go_to_hurt_state() -> void:
	status = ZumbiState.hurt

	anim.play("hurt")

	velocity.x = 0

	tempo_no_hurt = 0.0

	area_ataque.monitoring = false


func hurt_state() -> void:
	tempo_no_hurt += get_physics_process_delta_time()

	if tempo_no_hurt >= tempo_hurt:
		go_to_chase_state()
		return


func go_to_death_state() -> void:
	status = ZumbiState.death

	anim.play("death")

	velocity.x = 0

	area_ataque.monitoring = false

	$CollisionShape2D.set_deferred("disabled", true)

	set_physics_process(false)

	await anim.animation_finished

	queue_free()
