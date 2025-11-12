extends Control

@onready var start_button: TextureButton = $VBoxContainer/StartButton
@onready var credit_button: TextureButton = $VBoxContainer/CreditButton
@onready var quit_button: TextureButton = $VBoxContainer/QuitButton
@onready var title_label: Label = $Title
@onready var fade_rect: ColorRect = $FadeRect
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var sfx_hover: AudioStreamPlayer = $SFX_Hover
@onready var sfx_click: AudioStreamPlayer = $SFX_Click

func _ready():
	# Awal kondisi fade
	fade_rect.modulate.a = 1.0
	anim.play("fade_in")

	# Connect tombol
	start_button.pressed.connect(_on_start_pressed)
	credit_button.pressed.connect(_on_credit_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Hover efek suara dan skala
	for btn in [start_button, credit_button, quit_button]:
		btn.mouse_entered.connect(func(): _on_button_hovered(btn))
		btn.mouse_exited.connect(func(): _on_button_exited(btn))

	# Intro animasi menu
	title_label.modulate.a = 0
	for btn in [start_button, credit_button, quit_button]:
		btn.modulate.a = 0
	anim.play("menu_intro")


func _on_start_pressed():
	_play_click_sfx()
	anim.play("fade_out")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/Menu/prologue.tscn")


func _on_credit_pressed():
	_play_click_sfx()
	anim.play("fade_out")
	await anim.animation_finished
	get_tree().change_scene_to_file("res://scenes/Menu/credits.tscn")


func _on_quit_pressed():
	_play_click_sfx()
	get_tree().quit()


func _on_button_hovered(btn: TextureButton):
	if sfx_hover:
		sfx_hover.play()
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.1, 1.1), 0.15).set_trans(Tween.TRANS_SINE)


func _on_button_exited(btn: TextureButton):
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)


func _play_click_sfx():
	if sfx_click:
		sfx_click.play()
