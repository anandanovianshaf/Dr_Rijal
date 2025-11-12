extends Control

@onready var play_button: TextureButton = $MenuContainer/VBoxContainer/PlayButton
@onready var tutorial_button: TextureButton = $MenuContainer/VBoxContainer/TutorialButton
@onready var credit_button: TextureButton = $MenuContainer/VBoxContainer/CreditButton
@onready var quit_button: TextureButton = $MenuContainer/VBoxContainer/QuitButton

@onready var sfx_hover: AudioStreamPlayer = $AudioStreamPlayer # Ganti nama node ke "AudioStreamPlayer"
@onready var sfx_click: AudioStreamPlayer = $AudioStreamPlayer # Kalau mau pisah hover & click, duplikasi node ini

func _ready():
	# kumpulkan semua tombol biar efisien
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

	# beri delay sedikit supaya SFX sempat terdengar sebelum pindah scene
	await get_tree().create_timer(0.2).timeout

	match button.name:
		"PlayButton":
			get_tree().change_scene_to_file("res://scenes/Menu/prologue.tscn")
		"TutorialButton":
			get_tree().change_scene_to_file("res://scenes/Menu/tutorial.tscn")
		"CreditButton":
			get_tree().change_scene_to_file("res://scenes/Menu/credits.tscn")
		"QuitButton":
			get_tree().quit()
