extends Area2D

@export var next_level: String = ""


func _on_body_entered(body: Node2D) -> void:
	if body.name != "player":
		return
	
	set_deferred("monitoring", false)
	call_deferred("load_next_scene")


func load_next_scene() -> void:
	var caminho = "res://scenes/" + next_level + ".tscn"
	
	print("Trocando para: ", caminho)
	
	var erro = get_tree().change_scene_to_file(caminho)
	
	print("Resultado da troca: ", erro)
