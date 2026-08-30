extends Camera2D

@onready var alvo: Node2D = get_parent().get_node("player")


func _ready() -> void:
	print("CAMERA INICIOU")
	print("ALVO: ", alvo)
	
	global_position = alvo.global_position


func _physics_process(_delta: float) -> void:
	global_position = alvo.global_position
