extends Area2D
@onready var game_manager: Node = $"../GameManager"


func _on_body_entered(body):
	if body.name == "Player":
		body.respawn()
