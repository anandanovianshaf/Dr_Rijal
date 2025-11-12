extends Control

@onready var proceed := $Panel/VBox/ProceedButton as Button
@onready var quit    := $Panel/VBox/QuitButton    as Button

func _ready() -> void:
	proceed.pressed.connect(_on_proceed)
	quit.pressed.connect(_on_quit)

func _on_proceed() -> void:
	var next := GameManager.current_stage + 1
	var path := "res://scenes/Stage%d.tscn" % next
	if ResourceLoader.exists(path):
		GameManager.current_stage = next   # increment BEFORE change
		get_tree().change_scene_to_file(path)
	else:
		print("⚠️  No stage %d – returning to main menu" % next)
		get_tree().change_scene_to_file("res://scenes/Main/MainMenu.tscn")

func _on_quit() -> void:
	get_tree().change_scene_to_file("res://scenes/Main/MainMenu.tscn")
