extends CharacterBody2D

# --- PROPERTI PLAYER ---
@export var speed: float = 350.0
var health: int = 3
signal health_changed(new_health: int)

# --- VARIABEL BARU UNTUK REWARD/PENALTY ---
var is_frozen: bool = false # Status "beku" untuk penalti
var base_speed: float = 0.0 # Untuk menyimpan kecepatan asli

# --- PRELOAD ASET ---
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

@export var lock_on_scene: PackedScene
var peluru_scene = preload("res://Bullet.tscn")

# --- NODE YANG DIPERLUKAN ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var input_timer = $InputTimer
@onready var shooting_ui = get_tree().get_first_node_in_group("shooting_ui")
@onready var input_timer_display = get_tree().get_first_node_in_group("input_timer_display")
@onready var target_finder = $TargetFinder
# --- NODE TIMER BARU ---
@onready var penalty_timer = $PenaltyTimer
@onready var reward_timer = $RewardTimer

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
	await get_tree().process_frame
	
	base_speed = speed # <-- SIMPAN KECEPATAN ASLI

	if lock_on_scene:
		lock_on_instance = lock_on_scene.instantiate()
		get_parent().add_child(lock_on_instance)
		lock_on_instance.visible = false 

	# Hubungkan semua sinyal
	shoot_cooldown_timer.timeout.connect(_on_shoot_cooldown_timeout)
	input_timer.timeout.connect(_on_input_timer_timeout)
	animated_sprite.animation_finished.connect(_on_animated_sprite_animation_finished)
	target_finder.body_entered.connect(_on_target_finder_body_entered)
	target_finder.body_exited.connect(_on_target_finder_body_exited)
	# --- HUBUNGKAN TIMER BARU ---
	penalty_timer.timeout.connect(_on_penalty_timer_timeout)
	reward_timer.timeout.connect(_on_reward_timer_timeout)
	
	# Mulai cooldown pertama kali
	var settings = GameManager.get_current_stage_settings()
	shoot_cooldown_timer.start(settings.cooldown_time)
	health_changed.emit(health)

# --- FUNGSI _physics_process YANG DIPERBARUI ---
func _physics_process(_delta):
	find_closest_target()
	update_lock_on_visual()

	# --- 3. LOGIKA GERAK (DENGAN PENALTI) ---
	if not is_frozen:
		# Jika TIDAK beku, bergerak normal
		var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_direction * speed
		move_and_slide()
	else:
		# Jika BEKU, paksa berhenti
		velocity = Vector2.ZERO
		move_and_slide()

	# --- 4. LOGIKA ANIMASI (TETAP KONDISIONAL) ---
	if state == "idle" or state == "walk":
		if velocity.length() > 0:
			state = "walk"
			animated_sprite.play("walk")
		else:
			state = "idle"
			animated_sprite.play("idle")
		
	# --- 5. LOGIKA FLIP (JUGA DENGAN PENALTI) ---
	if not is_frozen:
		if velocity.x < 0:
			animated_sprite.flip_h = false # Aset hadap KIRI
		elif velocity.x > 0:
			animated_sprite.flip_h = true # Balik hadap KANAN
	
func _input(event):
	# ... (Fungsi _input Anda sudah benar, tidak perlu diubah)
	if not is_in_shoot_mode:
		return
	if not event.is_pressed():
		return
	var is_arrow_key = event.is_action("ui_up") or \
					   event.is_action("ui_down") or \
					   event.is_action("ui_left") or \
					   event.is_action("ui_right")
	if is_arrow_key:
		var correct_key = sequence_to_press[current_input_index]
		if event.is_action(correct_key):
			print("Panah BENAR!")
			current_input_index += 1
			update_shooting_ui()
			if current_input_index == sequence_to_press.size():
				success_shot()
		else:
			print("Panah SALAH!")
			fail_shot()	
# ======================================================================
# FUNGSI LOGIKA TEMBAK (AYODANCE)
# ======================================================================

func start_shooting_sequence():
	# ... (Fungsi ini sudah benar, tidak perlu diubah)
	if locked_target == null:
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)
		return
	is_in_shoot_mode = true
	state = "shoot"
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
	start_visual_countdown() 

# --- FUNGSI success_shot YANG DIPERBARUI ---
func success_shot():
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false

	if locked_target == null or not is_instance_valid(locked_target):
		fail_shot() 
		return

	print("BERHASIL! Menembak ", locked_target.name)
	# --- TAMBAHKAN LOGIKA MENEMBAK BARU INI ---
	# 1. Buat instance (salinan) peluru
	var new_bullet = peluru_scene.instantiate()

	# 2. Beri tahu peluru siapa targetnya
	new_bullet.target = locked_target

	# 3. Atur posisi awal peluru
	# (Gunakan $PistolPosition jika Anda buat, jika tidak, gunakan global_position)
	if has_node("PistolPosition"):
		new_bullet.global_position = $PistolPosition.global_position
	else:
		new_bullet.global_position = global_position # Spawn di tengah player

	# 4. Tambahkan peluru ke dunia game (bukan ke player)
	get_parent().add_child(new_bullet)

# --- FUNGSI fail_shot YANG DIPERBARUI ---
func fail_shot():
	if not is_in_shoot_mode: return
		
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false
	
	# --- LOGIKA PENALTI ---
	print("PENALTI: Beku 1 detik!")
	is_frozen = true # Bekukan player
	penalty_timer.start() # Mulai timer 1 detik
	# --- AKHIR PENALTI ---
	
	print("GAGAL MENEMBAK!")
	state = "fail_shoot"
	animated_sprite.play("fail_shoot")

# ======================================================================
# FUNGSI-FUNGSI LAIN (Tidak Berubah)
# ======================================================================

# --- FUNGSI LOGIKA AUTO-LOCK (TARGETING) ---
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
		lock_on_instance.visible = true
		lock_on_instance.global_position = locked_target.global_position
	else:
		lock_on_instance.visible = false

# --- FUNGSI LOGIKA UI (PANAH) ---
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

# --- FUNGSI SINYAL (SIGNAL HANDLERS) ---
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

		
# --- FUNGSI LOGIKA COUNTDOWN (TIMER ANGKA) ---
func start_visual_countdown():
	var settings = GameManager.get_current_stage_settings()
	var time = settings.input_time
	var current_second = floori(time) 
	_run_countdown_loop(current_second)

func _run_countdown_loop(seconds_left: int):
	while seconds_left > 0:
		if not is_in_shoot_mode:
			input_timer_display.visible = false
			return
		input_timer_display.set_number(seconds_left)
		input_timer_display.visible = true
		await get_tree().create_timer(1.0).timeout
		seconds_left -= 1
	input_timer_display.visible = false

# ======================================================================
# FUNGSI BARU UNTUK REWARD/PENALTI
# ======================================================================

# Dipanggil saat PenaltyTimer (1 detik) selesai
func _on_penalty_timer_timeout():
	is_frozen = false # Berhenti beku
	print("Penalti selesai. Player bisa gerak.")

# Dipanggil saat RewardTimer (1 detik) selesai
func _on_reward_timer_timeout():
	speed = base_speed # Kembalikan kecepatan ke normal
	print("Reward selesai. Kecepatan normal.")
