extends Control

@onready var back_button = $Button_Back
@onready var fade_rect = $ColorRect

func _ready():
	fade_rect.modulate.a = 1.0
	_fade_in_screen()
	back_button.pressed.connect(_on_back_pressed)

func _fade_in_screen():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 0.0, 1.0)

func _on_back_pressed():
	var tween = create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, 1.0)
	tween.finished.connect(_go_back)

func _go_back():
	get_tree().change_scene_to_file("res://scenes/MainMenu/MainMenu.tscn")
