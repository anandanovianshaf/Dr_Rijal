extends Node2D

@onready var player: Node = $Player
@onready var global_timer: Timer = $GlobalTimer
@onready var camera: Camera2D = $Camera2D
@onready var game_over: Control = $GameOver

var is_game_over: bool = false

func _ready():
	# --- LOGIKA KONEKSI DIPERBARUI ---
	if player:
		# 1. Tetap hubungkan 'health_changed' (untuk UI/HUD)
		if player.has_signal("health_changed"):
			player.health_changed.connect(_on_player_health_changed)
			
		# 2. Hubungkan sinyal 'died' YANG BARU
		if player.has_signal("died"):
			player.died.connect(_on_player_died)
	# --- AKHIR PERBARUAN ---

	if camera:
		var cam = $Camera2D
		cam.make_current()
		camera.position_smoothing_enabled = true
		camera.position_smoothing_speed = 8.0
		camera.global_position = player.global_position

# --- FUNGSI INI DIPERBARUI ---
func _on_player_health_changed(new_health: int) -> void:
	if is_game_over:
		return
		
	# HANYA untuk update UI, JANGAN panggil game over
	print("GAME.GD: Player HP sekarang ", new_health)
	
	# HAPUS BLOK INI DARI SINI:
	# if new_health <= 0:
	# 	 is_game_over = true
	# 	 _go_to_game_over()

# --- FUNGSI BARU ---
# Fungsi ini HANYA akan dipanggil setelah animasi 'dead' Player selesai
func _on_player_died():
	if is_game_over:
		return
		
	is_game_over = true
	
	# Panggil 'go_to_game_over' dengan aman (deferred)
	_go_to_game_over.call_deferred()

# --- Sisa script tidak berubah ---
func _on_global_timer_timeout() -> void:
	if is_game_over:
		return
	if player and player.health > 0:
		is_game_over = true
		_go_to_stage_clear()

func _go_to_stage_clear():
	get_tree().change_scene_to_file("res://scenes/StageClear.tscn")

func _go_to_game_over():
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _process(_delta: float) -> void:
	if camera and player:
		camera.global_position = player.global_position
