extends Control

@onready var video = $Video
@onready var fade = $ColorRect
@onready var prompt = $Label_Prompt      # "Press Enter to Start"

var fade_in_done = false
var video_ended = false
var video_skipped = false
var video_length = 28.0  # durasi video dalam detik

func _ready():
	# Sembunyikan label dulu
	prompt.visible = false
	
	# Mulai dari layar putih
	fade.modulate.a = 1.0
	set_process_input(true)
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
	if video_ended:
		return
	video_ended = true
	video.stop()
	prompt.visible = true      # Muncul label enter

func _input(event):
	if fade_in_done and not video_ended:
		if event.is_action_pressed("ui_cancel") and not video_skipped: # ESC
			video_skipped = true
			_skip_to_end_of_video()
	elif video_ended:
		if event.is_action_pressed("ui_accept"): # ENTER
			_fade_in_to_game()

func _skip_to_end_of_video():
	if video.stream:
		video.stream_position = video_length - 0.1   # langsung loncat ke akhir video
		await get_tree().process_frame               # tunggu frame akhir dirender
		video.stop()                                 # berhenti di frame terakhir
	_on_video_finished()                            # trigger akhir

func _fade_in_to_game():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	tween.finished.connect(_go_to_game)

func _go_to_game():
	get_tree().change_scene_to_file("res://scenes/Menu/MainMenu.tscn")
