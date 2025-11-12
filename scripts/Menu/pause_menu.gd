extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var fade_bg = $ColorRect

func _ready():
	visible = false
	modulate.a = 0.0  # awalnya transparan

	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func show_pause_menu():
	visible = true
	get_tree().paused = true  # pause semua scene kecuali UI
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func hide_pause_menu():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.finished.connect(func():
		visible = false
		get_tree().paused = false
	)

func _on_continue_pressed():
	hide_pause_menu()

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu/main_menu.tscn")
