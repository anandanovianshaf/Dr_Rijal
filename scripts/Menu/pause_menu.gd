extends Control

@onready var continue_button = $VBoxContainer/ContinueButton
@onready var exit_button = $VBoxContainer/ExitButton
@onready var fade_bg = $ColorRect
@onready var menu_box = $VBoxContainer

func _ready():
	visible = false
	modulate.a = 0.0
	menu_box.scale = Vector2(0.7, 0.7)  # mulai lebih kecil
	continue_button.pressed.connect(_on_continue_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

func show_pause_menu():
	visible = true
	get_tree().paused = true
	
	var tween = create_tween()
	tween.tween_property(fade_bg, "modulate:a", 0.5, 0.2)  # latar gelap muncul
	tween.parallel().tween_property(menu_box, "scale", Vector2.ONE, 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 1.0, 0.25)

func hide_pause_menu():
	var tween = create_tween()
	tween.tween_property(menu_box, "scale", Vector2(0.7, 0.7), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(fade_bg, "modulate:a", 0.0, 0.2)
	tween.finished.connect(func():
		visible = false
		get_tree().paused = false
	)

func _on_continue_pressed():
	hide_pause_menu()

func _on_exit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu/main_menu.tscn")
