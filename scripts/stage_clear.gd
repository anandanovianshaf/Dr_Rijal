extends Control

@onready var proceed_button = $Panel/VBox/ProceedButton
@onready var quit_button = $Panel/VBox/QuitButton

func _ready():
	proceed_button.pressed.connect(_on_proceed_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_proceed_pressed():
	# Naikkan stage global
	GameManager.current_stage += 1

	# Buat path otomatis berdasarkan nomor stage
	var next_scene_path = "res://scenes/Game" + str(GameManager.current_stage) + ".tscn"

	# Cek dulu apakah file scene-nya ada
	if ResourceLoader.exists(next_scene_path):
		get_tree().change_scene_to_file(next_scene_path)
	else:
		print("⚠️ Scene berikutnya tidak ditemukan:", next_scene_path)
		get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn") # fallback ke menu

func _on_quit_pressed():
	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")


func _on_quit_button_pressed() -> void:
	pass # Replace with function body.
