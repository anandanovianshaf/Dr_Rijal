extends Control

@onready var retry_button = $Panel/VBox/RetryButton
@onready var quit_button = $Panel/VBox/QuitButton

func _ready():
	retry_button.pressed.connect(_on_retry_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_retry_pressed():
	get_tree().change_scene_to_file("res://scenes/Stage2.tscn")  # restart current scene

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu/MainMenu.tscn")  # ganti ke menu utama kamu
