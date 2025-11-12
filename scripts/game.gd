extends Node2D

@onready var player: Node = $Player
@onready var global_timer: Timer = $GlobalTimer
@onready var game_over: Control = $GameOver
@onready var stopwatch: Stopwatch = $Stopwatch
@onready var timer_display: Label = $BorderLayer/TimerDisplay
@onready var camera: Camera2D = $Camera2D

var is_game_over: bool = false
var initial_time: float = 60.0

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
	
	# Inisialisasi stopwatch dengan waktu dari GlobalTimer
	if global_timer:
		initial_time = global_timer.wait_time
		
		# Setup stopwatch jika ada
		if stopwatch:
			stopwatch.reset()
			stopwatch.paused = false
			# Pastikan stopwatch tidak paused
			await get_tree().process_frame
			stopwatch.paused = false
	
	# Update tampilan timer awal
	_update_timer_display()

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
	
	# Pause stopwatch saat game over
	if stopwatch:
		stopwatch.paused = true
	
	# Panggil 'go_to_game_over' dengan aman (deferred)
	_go_to_game_over.call_deferred()

# --- Sisa script tidak berubah ---
func _on_global_timer_timeout() -> void:
	if is_game_over:
		return
	if player and player.health > 0:
		is_game_over = true
		
		# Pause stopwatch saat stage clear
		if stopwatch:
			stopwatch.paused = true
		
		_go_to_stage_clear()

func _go_to_stage_clear():
	get_tree().change_scene_to_file("res://scenes/StageClear.tscn")

func _go_to_game_over():
	get_tree().change_scene_to_file("res://scenes/GameOver.tscn")

func _process(_delta: float) -> void:
	if camera and player:
		camera.global_position = player.global_position
<<<<<<< HEAD

func _input(event):
	if event.is_action_pressed("ui_cancel"): # default tombol Esc
		if get_tree().paused:
			pause_menu.hide_pause_menu()
		else:
			pause_menu.show_pause_menu()
=======
	
	# Update tampilan countdown timer
	if not is_game_over:
		_update_timer_display()

func _update_timer_display() -> void:
	if not timer_display or is_game_over:
		return
	
	var remaining_time: float = 0.0
	
	# Prioritas: gunakan GlobalTimer.time_left (lebih reliable untuk countdown)
	if global_timer and global_timer.time_left > 0:
		remaining_time = global_timer.time_left
	# Fallback: gunakan stopwatch jika GlobalTimer tidak tersedia
	elif stopwatch and not stopwatch.paused:
		# Hitung waktu tersisa dari stopwatch (countdown)
		var elapsed = stopwatch.elapsed_time
		remaining_time = max(0.0, initial_time - elapsed)
	else:
		# Jika keduanya tidak tersedia, gunakan initial_time
		remaining_time = initial_time
	
	# Format waktu sebagai MM:SS (format standar countdown timer)
	var seconds = int(remaining_time)
	var minutes = seconds / 60  # Integer division untuk mendapatkan menit
	var secs = seconds % 60
	timer_display.text = "%02d:%02d" % [minutes, secs]
>>>>>>> 2a33c129e73b3a1bc64157355d09fadee263be32
