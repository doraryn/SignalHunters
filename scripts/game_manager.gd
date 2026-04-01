extends Node
@onready var life: Control = $"../CanvasLayer/Control/VBoxContainer/Life/Label"


func _ready():
	life.text = str(GameState.player_health)

func update_player_health (amount: int):
	GameState.player_health += amount
	life.text = str(GameState.player_health)

func _process(delta):
	if GameState.player_health == 0:
		print("Game over")
