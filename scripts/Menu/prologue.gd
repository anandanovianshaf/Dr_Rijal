extends Control

@onready var video = $Video
@onready var fade = $ColorRect
@onready var prompt = $Label_Prompt

var fade_in_done = false
var video_ended = false

func _ready():
	# Start fade-in from white to show the video
	fade.modulate.a = 1.0
	_fade_out_screen()

func _fade_out_screen():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.5)
	tween.finished.connect(_on_fade_out_done)

func _on_fade_out_done():
	fade_in_done = true
	video.play()
	video.finished.connect(_on_video_finished)

func _on_video_finished():
	video_ended = true
	prompt.visible = true

func _process(delta):
	# Detect when player presses Enter after video ends
	if video_ended and Input.is_action_just_pressed("ui_accept"):
		# Optional fade-to-white again before changing scene
		_fade_in_to_game()

func _fade_in_to_game():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	tween.finished.connect(_go_to_game)

func _go_to_game():
	get_tree().change_scene_to_file("res://Scenes/Game.tscn")
