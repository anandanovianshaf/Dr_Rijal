extends Control

@onready var play_button: TextureButton = $MenuContainer/PlayButton
@onready var tutorial_button: TextureButton = $MenuContainer/TutorialButton
@onready var credit_button: TextureButton = $MenuContainer/CreditButton
@onready var quit_button: TextureButton = $MenuContainer/QuitButton

@onready var sfx_hover: AudioStreamPlayer = $AudioHover
@onready var sfx_click: AudioStreamPlayer = $AudioClick

func _ready():
	# kumpulkan semua tombol biar gak connect satu-satu manual
	var buttons = [
		play_button,
		tutorial_button,
		credit_button,
		quit_button
	]

	for btn in buttons:
		btn.mouse_entered.connect(_on_button_hovered)
		btn.pressed.connect(_on_button_pressed.bind(btn))

func _on_button_hovered():
	if sfx_hover:
		sfx_hover.play()

func _on_button_pressed(button: TextureButton):
	if sfx_click:
		sfx_click.play()
	
	match button.name:
		"PlayButton":
			get_tree().change_scene_to_file("res://scenes/Prologue.tscn")
		"TutorialButton":
			get_tree().change_scene_to_file("res://scenes/Tutorial.tscn")
		"CreditButton":
			get_tree().change_scene_to_file("res://scenes/MainMenu/credits.tscn")
		"QuitButton":
			get_tree().quit()
