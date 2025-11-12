extends Control

@onready var back_button: TextureButton = $Button_Back
@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var sfx_click: AudioStreamPlayer = $AudioClick

func _ready():
	# Awal scene: mulai animasi masuk
	modulate.a = 0.0
	anim_player.play("fade_in")

	# Koneksi tombol
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	if sfx_click:
		sfx_click.play()

	# Tunggu 0.2 detik supaya SFX sempat diputar
	await get_tree().create_timer(0.2).timeout

	# Animasi keluar sebelum ganti scene
	anim_player.play("fade_out")
	await anim_player.animation_finished

	get_tree().change_scene_to_file("res://scenes/Menu/main_menu.tscn")
