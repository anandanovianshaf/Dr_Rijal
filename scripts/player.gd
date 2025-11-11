extends CharacterBody2D

# --- PROPERTI PLAYER ---
@export var speed: float = 350.0
var health: int = 3
signal health_changed(new_health: int)

# --- PRELOAD ASET (GANTI PATH-NYA!) ---
var arrow_textures = {
	"ui_up_normal": preload("res://assets/button/btn_top_one.png"),
	"ui_up_shiny": preload("res://assets/button/btn_hit_top.png"),
	"ui_down_normal": preload("res://assets/button/btn_bottom_one.png"),
	"ui_down_shiny": preload("res://assets/button/btn_hit_bottom.png"),
	"ui_left_normal": preload("res://assets/button/btn_left_one.png"),
	"ui_left_shiny": preload("res://assets/button/btn_hit_left.png"),
	"ui_right_normal": preload("res://assets/button/btn_right_one.png"),
	"ui_right_shiny": preload("res://assets/button/btn_hit_right.png")
}

# Link ke scene "LockOn" yang kita buat.
@export var lock_on_scene: PackedScene

# --- NODE YANG DIPERLUKAN ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var input_timer = $InputTimer
# Catatan: Ini akan error jika Anda belum menaruh ShootingUI di grup "shooting_ui"
# Jika error, ganti ini jadi: @onready var shooting_ui = $ShootingUI
@onready var shooting_ui = get_tree().get_first_node_in_group("shooting_ui")
@onready var input_timer_display = get_tree().get_first_node_in_group("input_timer_display")
@onready var target_finder = $TargetFinder

# --- VARIABEL LOGIKA TEMBAK ---
var state = "idle"
var is_in_shoot_mode = false
var sequence_to_press = [] # Urutan panah
var current_input_index = 0
var arrow_keys = ["ui_up", "ui_down", "ui_left", "ui_right"]

# --- VARIABEL AUTO-LOCK ---
var potential_targets = [] # Daftar musuh dalam jangkauan
var locked_target = null
var lock_on_instance = null

# ======================================================================
# FUNGSI-FUNGSI BAWAAN GODOT
# ======================================================================

func _ready():
	# Buat instance "LockOn" sekali saja
	if lock_on_scene:
		lock_on_instance = lock_on_scene.instantiate()

	# Hubungkan semua sinyal timer & area
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_timeout)
	input_timer.timeout.connect(_on_input_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	target_finder.body_entered.connect(_on_target_finder_body_entered)
	target_finder.body_exited.connect(_on_target_finder_body_exited)
	
	# Mulai cooldown pertama kali
	var settings = GameManager.get_current_stage_settings()
	shoot_cooldown_timer.start(settings.cooldown_time)
	# Kirim sinyal HP awal
	health_changed.emit(health)

# --- INI FUNGSI YANG DIPERBARUI ---
func _physics_process(_delta):
	# 1. Update target terdekat
	find_closest_target()
	
	# 2. Pindahkan sprite "LockOn"
	update_lock_on_visual()

	# --- 3. LOGIKA GERAK (BERJALAN SELALU) ---
	# Kode ini sekarang berjalan SETIAP FRAME,
	# tidak peduli apa 'state' Anda.
	var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * speed
	move_and_slide()

	# --- 4. LOGIKA ANIMASI (TETAP KONDISIONAL) ---
	# Kita HANYA ubah animasi gerak JIKA kita
	# tidak sedang dalam 'state' shoot atau fail_shoot.
	if state == "idle" or state == "walk":
		if velocity.length() > 0:
			state = "walk"
			animated_sprite.play("walk")
		else:
			state = "idle"
			animated_sprite.play("idle")
		
	# --- 5. LOGIKA FLIP (BERJALAN SELALU) ---
	# Logika membalik sprite (Aset asli hadap KIRI - Sesuai perbaikan kita)
	# Ini juga harus berjalan setiap frame.
	if velocity.x < 0:
		animated_sprite.flip_h = false # JANGAN dibalik (karena sudah hadap kiri)
	elif velocity.x > 0:
		animated_sprite.flip_h = true # BALIK (agar hadap kanan)
	
	# Kita HAPUS 'else: velocity = ZERO' block.

func _input(event):
	if not is_in_shoot_mode:
		return
	
	if not event.is_pressed():
		return

	# 1. Cek dulu apakah ini tombol panah
	var is_arrow_key = event.is_action("ui_up") or \
					   event.is_action("ui_down") or \
					   event.is_action("ui_left") or \
					   event.is_action("ui_right")
					   
	if is_arrow_key:
		# 2. Oke, ini tombol panah. Apakah ini tombol yang BENAR?
		var correct_key = sequence_to_press[current_input_index]
		
		if event.is_action(correct_key):
			# --- BENAR ---
			print("Panah BENAR!")
			current_input_index += 1
			update_shooting_ui() # Ini akan ganti jadi "shiny"
			
			if current_input_index == sequence_to_press.size():
				success_shot()
		else:
			# --- SALAH ---
			print("Panah SALAH!")
			fail_shot()	
# ======================================================================
# FUNGSI LOGIKA TEMBAK (AYODANCE)
# ======================================================================

func start_shooting_sequence():
	if locked_target == null:
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)
		return

	is_in_shoot_mode = true
	state = "shoot" # Player masuk ke animasi 'shoot'
	animated_sprite.play("shoot")
	
	var settings = GameManager.get_current_stage_settings()
	var arrow_count = settings.arrow_count
	var input_time = settings.input_time
	
	sequence_to_press.clear()
	for i in arrow_count:
		sequence_to_press.append(arrow_keys.pick_random())
		
	print("URUTAN BARU: ", sequence_to_press)
	
	current_input_index = 0
	update_shooting_ui() 
	shooting_ui.show()
	input_timer.start(input_time)
	start_visual_countdown() # Panggil timer angka kita (terlihat)

func success_shot():
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false
	
	if locked_target == null or not is_instance_valid(locked_target):
		fail_shot() 
		return
		
	print("BERHASIL! Menembak ", locked_target.name)
	
	if locked_target.global_position.x < global_position.x:
		animated_sprite.flip_h = true 
	else:
		animated_sprite.flip_h = false
		
	if locked_target.has_method("take_damage"):
		locked_target.take_damage(100) # Tembakan instakill

func fail_shot():
	if not is_in_shoot_mode: return
		
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false
	
	print("GAGAL MENEMBAK!")
	state = "fail_shoot"
	animated_sprite.play("fail_shoot")

# ======================================================================
# FUNGSI LOGIKA AUTO-LOCK (TARGETING)
# ======================================================================

func find_closest_target():
	if potential_targets.is_empty():
		locked_target = null
		return

	var closest_dist = 99999
	var closest_enemy = null
	
	for enemy in potential_targets:
		if not is_instance_valid(enemy):
			continue
			
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy
			
	locked_target = closest_enemy

func update_lock_on_visual():
	if not lock_on_instance: return 

	if locked_target:
		if lock_on_instance.get_parent() == null:
			locked_target.add_child(lock_on_instance)
			lock_on_instance.global_position = locked_target.global_position
	else:
		if lock_on_instance.get_parent() != null:
			lock_on_instance.get_parent().remove_child(lock_on_instance)

# ======================================================================
# FUNGSI LOGIKA UI (PANAH)
# ======================================================================

func update_shooting_ui():
	var settings = GameManager.get_current_stage_settings()
	var arrow_count = settings.arrow_count
	
	for i in 8:
		var arrow_node_path = "HBoxContainer/Arrow" + str(i + 1)
		var arrow_node = shooting_ui.get_node_or_null(arrow_node_path)
		
		if not arrow_node: continue 

		if i < arrow_count:
			arrow_node.visible = true
			
			var key_name = sequence_to_press[i]
			
			if i < current_input_index:
				arrow_node.texture = arrow_textures[key_name + "_shiny"]
			else:
				arrow_node.texture = arrow_textures[key_name + "_normal"]
		
		else:
			arrow_node.visible = false

# ======================================================================
# FUNGSI SINYAL (SIGNAL HANDLERS)
# ======================================================================

func _on_shoot_cooldown_timeout():
	if state == "idle" or state == "walk":
		start_shooting_sequence()

func _on_input_timer_timeout():
	if is_in_shoot_mode:
		fail_shot()

func _on_animated_sprite_animation_finished():
	var anim_name = animated_sprite.animation
	
	if anim_name == "shoot" or anim_name == "fail_shoot":
		state = "idle"
		animated_sprite.play("idle")
		
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)

# --- Sinyal untuk 'TargetFinder' (Area2D) ---
func _on_target_finder_body_entered(body):
	if body.is_in_group("virus"):
		potential_targets.append(body)

func _on_target_finder_body_exited(body):
	if body.is_in_group("virus"):
		potential_targets.erase(body) 
		if body == locked_target:
			locked_target = null

# --- Fungsi untuk diserang musuh ---
func take_damage(amount):
	health -= amount
	print("Player HP: ", health)
	
	health_changed.emit(health)
	
	if health <= 0:
		print("PLAYER MATI!")
		get_tree().reload_current_scene()
		
		# ======================================================================
# FUNGSI LOGIKA COUNTDOWN (TIMER ANGKA)
# ======================================================================

# Fungsi ini dipanggil untuk memulai hitungan mundur visual
func start_visual_countdown():
	# Ambil waktu dari GameManager
	var settings = GameManager.get_current_stage_settings()
	var time = settings.input_time
	# Ubah 3.0 atau 4.0 jadi integer (angka bulat)
	var current_second = floori(time) 
	
	# Kita panggil fungsi async-nya (yang bisa "menunggu")
	# Kita tidak pakai 'await' di sini agar fungsi ini berjalan
	# di "latar belakang" tanpa menghentikan sisa kode.
	_run_countdown_loop(current_second)

# Fungsi ini berjalan "di latar belakang" menggunakan async/await
func _run_countdown_loop(seconds_left: int):
	while seconds_left > 0:
		# Cek apakah player sudah selesai (berhasil/gagal)
		# Jika ya, hentikan hitungan mundur ini
		if not is_in_shoot_mode:
			input_timer_display.visible = false
			return # Keluar dari loop

		# Tampilkan angka (menggunakan fungsi dari NumberDisplay.gd)
		input_timer_display.set_number(seconds_left)
		input_timer_display.visible = true
		
		# Tunggu 1 detik
		await get_tree().create_timer(1.0).timeout
		
		# Kurangi angka
		seconds_left -= 1
	
	# Setelah loop selesai (angka jadi 0)
	input_timer_display.visible = false
