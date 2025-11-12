extends CharacterBody2D

# --- PROPERTI PLAYER ---
@export var speed: float = 500.0
var health: int = 3
signal health_changed(new_health: int)
signal died # <-- SINYAL BARU!

# --- VARIABEL BARU UNTUK REWARD/PENALTY ---
var is_frozen: bool = false
var base_speed: float = 0.0
var is_dead: bool = false # <-- VARIABEL BARU!

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
var peluru_scene = preload("res://scenes/Bullet.tscn")

# --- NODE YANG DIPERLUKAN ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var input_timer = $InputTimer
@onready var shooting_ui = get_tree().get_first_node_in_group("shooting_ui")
@onready var input_timer_display = get_tree().get_first_node_in_group("input_timer_display")
@onready var target_finder = $TargetFinder
@onready var penalty_timer = $PenaltyTimer
@onready var reward_timer = $RewardTimer

# --- VARIABEL LOGIKA TEMBAK ---
var state = "idle"
var is_in_shoot_mode = false
var sequence_to_press = [] 
var current_input_index = 0
var arrow_keys = ["ui_up", "ui_down", "ui_left", "ui_right"]

# --- VARIABEL AUTO-LOCK ---
var potential_targets = [] 
var locked_target = null
var lock_on_instance = null

# ======================================================================
# FUNGSI-FUNGSI BAWAAN GODOT
# ======================================================================

func _ready():
	await get_tree().process_frame
	
	base_speed = speed 

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
	penalty_timer.timeout.connect(_on_penalty_timer_timeout)
	reward_timer.timeout.connect(_on_reward_timer_timeout)
	
	var settings = GameManager.get_current_stage_settings()
	shoot_cooldown_timer.start(settings.cooldown_time)
	health_changed.emit(health)

func _physics_process(_delta):
	# --- JANGAN PROSES APAPUN JIKA SUDAH MATI ---
	if is_dead:
		return

	find_closest_target()
	update_lock_on_visual()

	if not is_frozen:
		var input_direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		velocity = input_direction * speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO
		move_and_slide()

	if state == "idle" or state == "walk":
		if velocity.length() > 0:
			state = "walk"
			animated_sprite.play("walk")
		else:
			state = "idle"
			animated_sprite.play("idle")
		
	if not is_frozen:
		if velocity.x < 0:
			animated_sprite.flip_h = false # Aset hadap KIRI
		elif velocity.x > 0:
			animated_sprite.flip_h = true # Balik hadap KANAN
	
func _input(event):
	# --- PERUBAHAN DI SINI ---
	# Jika player MATI atau BEKU, jangan proses input tembakan
	if is_dead or is_frozen:
		return
	# --- AKHIR PERUBAHAN ---
		
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

func success_shot():
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false
	
	print("REWARD: Kecepatan x1.5 selama 1 detik!")
	speed = base_speed * 1.5
	reward_timer.start() 

	if locked_target == null or not is_instance_valid(locked_target):
		fail_shot() 
		return

	print("BERHASIL! Menembak ", locked_target.name)
	var new_bullet = peluru_scene.instantiate()
	new_bullet.target = locked_target
	if has_node("PistolPosition"):
		new_bullet.global_position = $PistolPosition.global_position
	else:
		new_bullet.global_position = global_position
	get_parent().add_child(new_bullet)

func fail_shot():
	if not is_in_shoot_mode: return
		
	is_in_shoot_mode = false
	input_timer.stop()
	shooting_ui.hide()
	input_timer_display.visible = false
	
	print("PENALTI: Beku 1 detik!")
	is_frozen = true 
	penalty_timer.start() 
	
	print("GAGAL MENEMBAK!")
	state = "fail_shoot"
	animated_sprite.play("fail_shoot")

# ======================================================================
# FUNGSI-FUNGSI LAIN
# ======================================================================

func find_closest_target():
	# ... (Fungsi ini tidak berubah)
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
	# ... (Fungsi ini tidak berubah)
	if not lock_on_instance: return 
	if locked_target:
		lock_on_instance.visible = true
		lock_on_instance.global_position = locked_target.global_position
	else:
		lock_on_instance.visible = false

func update_shooting_ui():
	# ... (Fungsi ini tidak berubah)
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

# --- FUNGSI _on_animated_sprite_animation_finished (DIPERBARUI) ---
func _on_animated_sprite_animation_finished():
	var anim_name = animated_sprite.animation
	
	if anim_name == "shoot" or anim_name == "fail_shoot":
		state = "reload"
		animated_sprite.play("reload")
		
	elif anim_name == "reload":
		state = "idle"
		animated_sprite.play("idle")
		
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)

	# --- PERUBAHAN DI SINI ---
	elif anim_name == "hit":
		# Animasi 'hit' selesai.
		is_frozen = false # <-- PERUBAHAN: Berhenti beku
		state = "idle"
		animated_sprite.play("idle")
	# --- AKHIR PERUBAHAN ---
	
	elif anim_name == "dead":
		died.emit()

func _on_target_finder_body_entered(body):
	if body.is_in_group("virus"):
		potential_targets.append(body)

func _on_target_finder_body_exited(body):
	if body.is_in_group("virus"):
		potential_targets.erase(body) 
		if body == locked_target:
			locked_target = null

# --- Fungsi untuk diserang musuh (DIPERBARUI) ---
# --- Fungsi untuk diserang musuh (DIPERBARUI) ---
# --- Fungsi untuk diserang musuh (DIPERBARUI) ---
func take_damage(amount):
	# --- PERUBAHAN DI SINI ---
	# Jika player MATI atau sedang BEKU (is_frozen)
	# 'is_frozen' akan aktif saat 'fail_shot' ATAU 'hit'
	if is_dead or is_frozen:
		return
	# --- AKHIR PERUBAHAN ---

	health -= amount
	print("Player HP: ", health)
	health_changed.emit(health)
	
	if health <= 0 and not is_dead:
		die()
	# --- PERUBAHAN DI SINI ---
	elif health > 0:
		# Jika kita kena hit TAPI belum mati...
		print("PLAYER KENA HIT! Membeku...")
		is_frozen = true # <-- PERUBAHAN: Kembalikan 'is_frozen = true'
		state = "hit"
		animated_sprite.play("hit") # Mainkan animasi 'hit'
		# Kita TIDAK menyalakan PenaltyTimer. 'is_frozen'
		# akan dimatikan oleh animasi 'hit' saat selesai.
	# --- AKHIR PERUBAHAN ---
	
	
# --- FUNGSI KEMATIAN BARU ---
func die():
	is_dead = true # Set flag agar tidak bisa 'take_damage' lagi
	is_frozen = true # Berhenti bergerak (dari _physics_process)
	state = "dead" # Ubah state
	
	print("PLAYER MATI! Memainkan animasi...")
	
	# Matikan semua tabrakan & sensor
	$CollisionShape2D.set_deferred("disabled", true)
	target_finder.set_deferred("monitoring", false)
	
	# Mainkan animasi 'dead' (hantu)
	animated_sprite.play("dead")
	
	# Kita tidak emit 'died' di sini. Kita emit di
	# _on_animated_sprite_animation_finished agar
	# kita TAHU animasinya sudah selesai.

# --- FUNGSI LOGIKA COUNTDOWN (TIMER ANGKA) ---
# ... (Fungsi start_visual_countdown dan _run_countdown_loop tidak berubah)
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

# --- FUNGSI REWARD/PENALTI (Tidak Berubah) ---
func _on_penalty_timer_timeout():
	is_frozen = false
	print("Penalti selesai. Player bisa gerak.")

func _on_reward_timer_timeout():
	speed = base_speed
	print("Reward selesai. Kecepatan normal.")
# --- FUNGSI PENYEMBUHAN (untuk Potion) ---
func heal(amount: int):
	if is_dead:
		return  # kalau udah mati, gak bisa disembuhkan

	# batas HP maksimal
	var max_health = 3

	if health < max_health:
		health += amount
		if health > max_health:
			health = max_health

		print("Player disembuhkan! HP sekarang:", health)
		health_changed.emit(health)

		# (Opsional) mainkan animasi atau efek heal
		if animated_sprite.animation != "heal":
			animated_sprite.play("heal")
	else:
		print("HP sudah penuh! Potion terbuang percuma.")
