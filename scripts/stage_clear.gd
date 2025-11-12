extends Control

@onready var proceed_button = $Panel/VBox/ProceedButton

func _ready():
	proceed_button.pressed.connect(_on_proceed_pressed)

func _on_proceed_pressed():
	GameManager.current_stage += 1  # Naikkan stage global
	get_tree().change_scene_to_file("res://scenes/Game" + str(GameManager.current_stage) + ".tscn")
