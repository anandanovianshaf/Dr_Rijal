extends CharacterBody2D

# --- PROPERTI PLAYER ---
@export var speed: float = 500.0
var health: int = 3
signal health_changed(new_health: int)
signal died

# --- VARIABEL BARU UNTUK REWARD/PENALTY ---
var is_frozen: bool = false
var base_speed: float = 0.0
var is_dead: bool = false

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

var player1_frames = preload("res://assets/character 1/Player1.tres")
var player2_frames = preload("res://assets/character 2/Player2.tres")
var player3_frames = preload("res://assets/character 3/Player3.tres")

@export var lock_on_scene: PackedScene
var peluru_scene = preload("res://scenes/Bullet.tscn")

var is_penalized: bool = false
# NOTE: AnimationPlayer node tidak ada di scene Game/Player (berdasarkan struktur),
# jadi kita HAPUS referensi langsung ke $AnimationPlayer untuk menghindari error.

# --- NODE YANG DIPERLUKAN ---
@onready var animated_sprite = $AnimatedSprite2D
@onready var shoot_cooldown_timer = $ShootCooldownTimer
@onready var input_timer = $InputTimer
@onready var shooting_ui = get_tree().get_first_node_in_group("shooting_ui")
@onready var input_timer_display = get_tree().get_first_node_in_group("input_timer_display")
@onready var target_finder = $TargetFinder
@onready var penalty_timer = $PenaltyTimer
@onready var reward_timer = $RewardTimer

# --- AUDIO ---
@onready var sfx_shoot = $SFX_Shoot
@onready var sfx_hit = $SFX_Hit
@onready var footstep_player = $FootstepPlayer #Footstep Player

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

#====Variable Footstep Player
var footstep_timer := 0.0
var footstep_interval := 0.3 # detik antar langkah

# ======================================================================
# READY
# ======================================================================
# ======================================================================
# FUNGSI-FUNGSI BAWAAN GODOT
# ======================================================================

func _ready():
# 1. TUNGGU 1 frame dulu.
	await get_tree().process_frame 
	# --- AKHIR PERBAIKAN ---

	# --- 2. LOGIKA GANTI KOSTUM (VERSI BARU DENGAN STAGE 3) ---
	# Sekarang kita cek GameManager.
	if GameManager.current_stage == 3:
		$AnimatedSprite2D.sprite_frames = player3_frames
		print("Memuat kostum Player 3")
	elif GameManager.current_stage == 2: # <-- PERBAIKAN: Gunakan 'elif'
		$AnimatedSprite2D.sprite_frames = player2_frames
		print("Memuat kostum Player 2")
	else: # <-- PERBAIKAN: Tambah ':' dan ganti ke player1_frames
		# Default (Stage 1)
		$AnimatedSprite2D.sprite_frames = player1_frames
		print("Memuat kostum Player 1")
	# --- AKHIR LOGIKA ---

	# --- 3. Sisa kode _ready() Anda (aman untuk dijalankan sekarang) ---
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

# ======================================================================
# PHYSICS PROCESS
# ======================================================================
func _physics_process(delta):
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

	# --- Animasi & Footstep ---
	if state in ["idle", "walk"]:
		if velocity.length() > 0:
			state = "walk"
			animated_sprite.play("walk")

			# ✅ Footstep logic
			footstep_timer += delta
			if footstep_timer >= footstep_interval:
				footstep_timer = 0.0
				play_footstep()
		else:
			state = "idle"
			animated_sprite.play("idle")
			footstep_timer = 0.0  # reset timer kalau berhenti

	# --- Arah hadap ---
	if not is_frozen:
		if velocity.x < 0:
			animated_sprite.flip_h = true
		elif velocity.x > 0:
			animated_sprite.flip_h = false

func play_footstep():
	if not footstep_player.playing:
		footstep_player.play()

# ======================================================================
# INPUT
# ======================================================================
func _input(event):
	if is_dead or is_frozen:
		return
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
# SHOOTING
# ======================================================================
func start_shooting_sequence():
	if locked_target == null:
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)
		return

	if shooting_ui == null or not is_instance_valid(shooting_ui):
		shooting_ui = get_tree().get_first_node_in_group("shooting_ui")

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

	if shooting_ui:
		shooting_ui.show()
	input_timer.start(input_time)
	start_visual_countdown()
	print("Start shooting seq — shooting_ui:", shooting_ui, " is_in_shoot_mode:", is_in_shoot_mode)

func success_shot():
	is_in_shoot_mode = false
	input_timer.stop()
	if shooting_ui:
		shooting_ui.hide()
	if input_timer_display:
		input_timer_display.visible = false
	
	# ✅ Play SFX
	if sfx_shoot:
		sfx_shoot.play()

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
	if not is_in_shoot_mode:
		return

	is_in_shoot_mode = false
	input_timer.stop()
	if shooting_ui:
		shooting_ui.hide()
	if input_timer_display:
		input_timer_display.visible = false

	print("PENALTI: Beku 1 detik!")
	is_frozen = true
	penalty_timer.start()

	print("GAGAL MENEMBAK!")
	state = "fail_shoot"
	animated_sprite.play("fail_shoot")

# ======================================================================
# FUNGSI TAMBAHAN
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
	if not lock_on_instance:
		return
	if locked_target:
		lock_on_instance.visible = true
		lock_on_instance.global_position = locked_target.global_position
	else:
		lock_on_instance.visible = false

func update_shooting_ui():
	var settings = GameManager.get_current_stage_settings()
	var arrow_count = settings.arrow_count
	# iterate using range to avoid strange 'for in 8' behaviour
	for i in range(8):
		var arrow_node_path = "HBoxContainer/Arrow" + str(i + 1)
		if not shooting_ui:
			continue
		var arrow_node = shooting_ui.get_node_or_null(arrow_node_path)
		if not arrow_node:
			continue

		if i < arrow_count:
			arrow_node.visible = true

			# --- Perbaikan bagian ini ---
			var key_name = ""
			if i < sequence_to_press.size():
				key_name = sequence_to_press[i]
			else:
				key_name = arrow_keys[0]

			if i < current_input_index:
				arrow_node.texture = arrow_textures[key_name + "_shiny"]
			else:
				arrow_node.texture = arrow_textures[key_name + "_normal"]
		else:
			arrow_node.visible = false

# ======================================================================
# TIMER & DAMAGE
# ======================================================================
func _on_shoot_cooldown_timeout():
	if is_dead:
		return

	await get_tree().process_frame
	find_closest_target()

	if locked_target == null:
		await get_tree().create_timer(0.15).timeout
		find_closest_target()

	# reload settings once for this function
	var settings = GameManager.get_current_stage_settings()

	if locked_target == null:
		shoot_cooldown_timer.start(settings.cooldown_time)
		return

	# Jika player sedang kena hit/penalti, kita tunggu berkala hingga sembuh
	if is_frozen or is_penalized or state == "hit":
		print("⛔ Skip shooting UI karena player sedang kena hit / penalti")

		var max_wait_time := 2.0
		var elapsed := 0.0
		while (is_frozen or is_penalized or state == "hit") and elapsed < max_wait_time:
			await get_tree().create_timer(0.2).timeout
			elapsed += 0.2

		# Re-check kondisi & apakah target masih valid
		find_closest_target()
		if locked_target == null:
			# restart cooldown and bail out
			shoot_cooldown_timer.start(settings.cooldown_time)
			print("⚠️ Gagal retry: target hilang atau masih penalti/ hit. Restart cooldown.")
			return

		if is_frozen or is_penalized or state == "hit":
			print("⚠️ Gagal retry: Player masih penalti / beku.")
			# restart cooldown
			shoot_cooldown_timer.start(settings.cooldown_time)
			return

	# at this point, safe to start shooting sequence
	start_shooting_sequence()

	# restart cooldown so system keeps cycling
	shoot_cooldown_timer.start(settings.cooldown_time)

func _on_input_timer_timeout():
	if is_in_shoot_mode:
		fail_shot()

func _on_animated_sprite_animation_finished():
	var anim_name = animated_sprite.animation

	if anim_name in ["shoot", "fail_shoot"]:
		state = "reload"
		animated_sprite.play("reload")

	elif anim_name == "reload":
		state = "idle"
		animated_sprite.play("idle")
		var settings = GameManager.get_current_stage_settings()
		shoot_cooldown_timer.start(settings.cooldown_time)

	elif anim_name == "hit":
		# animation finished => unfreeze (if we used animation for hit)
		is_frozen = false
		state = "idle"
		animated_sprite.play("idle")
		
		

	elif anim_name == "dead":
		died.emit()

# ======================================================================
# TARGET FINDER
# ======================================================================
func _on_target_finder_body_entered(body):
	if body.is_in_group("virus"):
		potential_targets.append(body)

func _on_target_finder_body_exited(body):
	if body.is_in_group("virus"):
		potential_targets.erase(body)
		if body == locked_target:
			locked_target = null

# ======================================================================
# DAMAGE / DEATH / HEAL
# ======================================================================
func take_damage(amount):
	# if already dead or currently frozen, ignore
	if is_dead or is_frozen:
		return
	health -= amount
	print("Player HP: ", health)
	health_changed.emit(health)

# 💢 Mainkan SFX saat kena hit
	if sfx_hit:
		sfx_hit.stop()  # biar suara nggak overlap kalau kena beruntun
		sfx_hit.play()

	if health <= 0 and not is_dead:
		die()
	elif health > 0:
		print("PLAYER KENA HIT! Membeku...")
		is_frozen = true
		state = "hit"
		animated_sprite.play("hit")
		# backup timer to ensure unfreeze if animation signal fails
		get_tree().create_timer(0.8).timeout.connect(func():
			if is_frozen and state == "hit":
				is_frozen = false
				state = "idle"
				animated_sprite.play("idle")
				print("Auto-unfreeze setelah animasi hit (backup).")
				print("✅ Auto-unfreeze selesai — state:", state, " is_frozen:", is_frozen, " penalized:", is_penalized)
		)

func die():
	is_dead = true
	is_frozen = true
	state = "dead"
	print("PLAYER MATI! Memainkan animasi...")
	$CollisionShape2D.set_deferred("disabled", true)
	target_finder.set_deferred("monitoring", false)
	animated_sprite.play("dead")

func heal(amount: int):
	if is_dead:
		return
	var max_health = 3
	if health < max_health:
		health = min(health + amount, max_health)
		print("Player disembuhkan! HP sekarang:", health)
		health_changed.emit(health)
		# play heal animation only if available
		print("HP sudah penuh! Potion terbuang percuma.")

# ======================================================================
# VISUAL COUNTDOWN
# ======================================================================
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
# REWARD & PENALTY
# ======================================================================
func _on_penalty_timer_timeout():
	is_frozen = false
	print("Penalti selesai. Player bisa gerak.")

func _on_reward_timer_timeout():
	speed = base_speed
	print("Reward selesai. Kecepatan normal.")
	
