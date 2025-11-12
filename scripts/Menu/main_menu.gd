extends Control

@onready var play_button = $MenuContainer/VBoxContainer/PlayButton
@onready var credits_button = $MenuContainer/VBoxContainer/CreditButton
@onready var quit_button = $MenuContainer/VBoxContainer/QuitButton
@onready var parallax_bg = $ParallaxBackground
@onready var bgm_player = $BGMPlayer

func _ready():
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Play BGM if not already playing
	if not bgm_player.playing:
		bgm_player.play()

func _on_play_pressed():
	print("Play pressed!")
	get_tree().change_scene_to_file("res://scenes/MainMenu/prologue.tscn")

func _on_credits_pressed():
	print("Credits pressed!")
	get_tree().change_scene_to_file("res://scenes/MainMenu/credits.tscn")

func _on_quit_pressed():
	print("Quit pressed!")
	get_tree().quit()

func _process(delta):
	if parallax_bg:
		parallax_bg.scroll_offset.x += 20 * delta
