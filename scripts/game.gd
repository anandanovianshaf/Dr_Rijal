extends Node2D

@onready var player: Node = $Player
@onready var global_timer: Timer = $GlobalTimer
@onready var camera: Camera2D = $Camera2D

var is_game_over: bool = false

func _ready():
	# Listen to player health changes for lose condition
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	# Set camera active and center on player
	if camera:
		var cam = $Camera2D
		cam.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		camera.global_position = player.global_position

func _on_player_health_changed(new_health: int) -> void:
	if is_game_over:
		return
	if new_health <= 0:
		is_game_over = true
		_go_to_game_over()

func _on_global_timer_timeout() -> void:
	if is_game_over:
		return
	# Win condition: timer finished and player still alive (>0)
	if player and player.health > 0:
		is_game_over = true
		_go_to_stage_clear()

func _go_to_stage_clear():
	get_tree().change_scene_to_file("res://scenes/StageClear.tscn")

func _go_to_game_over():
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _process(_delta: float) -> void:
	# Keep camera centered on player each frame
	if camera and player:
		camera.global_position = player.global_position
