extends CharacterBody2D

# --- PROPERTI (TIDAK BERUBAH) ---
@export var speed: float = 150.0
@export var health: int = 5
@export var stopping_distance: float = 24.0
@export var virus_scale: Vector2 = Vector2(0.6, 0.6)

@onready var animated_sprite = $AnimatedSprite2D
var player_node: Node2D = null

# --- TAMBAHAN 1: PRELOAD KOSTUM MONSTER ---
# (Pastikan path .tres Anda sudah benar)
var virus1_frames = preload("res://assets/Monster/Virus1.tres")
var virus2_frames = preload("res://assets/Monster/Virus2.tres")
var virus3_frames = preload("res://assets/Monster/Virus3.tres")
# --- AKHIR TAMBAHAN 1 ---


func _ready():
	# Tunggu 1 frame agar semua node (termasuk Player) sudah siap
	await get_tree().process_frame
	
	# --- TAMBAHAN 2: LOGIKA GANTI KOSTUM ---
	# Cek stage saat ini dari GameManager
	match GameManager.current_stage:
		3:
			animated_sprite.sprite_frames = virus3_frames
		2:
			animated_sprite.sprite_frames = virus2_frames
		_: # Default (Stage 1)
			animated_sprite.sprite_frames = virus1_frames
	# --- AKHIR TAMBAHAN 2 ---
	
	_find_player()
	animated_sprite.play("walk")
	# Kurangi safe margin untuk menghindari dorong-mendorong berlebih
	safe_margin = 0.01
	scale = virus_scale

func _physics_process(_delta):
	# (LOGIKA INI TIDAK SAYA UBAH)
	if not _is_player_valid():
		_find_player()
		return

	# Arahkan virus ke player
	var to_player := (player_node.global_position - global_position)
	var distance := to_player.length()
	if distance > 0:
		var direction := to_player / distance
		# Berhenti sedikit sebelum menyentuh player untuk mencegah jitter
		if distance <= stopping_distance:
			velocity = Vector2.ZERO
		else:
			velocity = direction * speed
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	# Animasi + orientasi sprite
	animated_sprite.play("walk")
	if velocity.x < 0:
		animated_sprite.flip_h = true
	elif velocity.x > 0:
		animated_sprite.flip_h = false


# --- Fungsi bantu ---
func _find_player():
	# (LOGIKA INI TIDAK SAYA UBAH)
	if get_parent().has_node("Player"):
		player_node = get_parent().get_node("Player")
	else:
		player_node = get_tree().get_first_node_in_group("player")

func _is_player_valid() -> bool:
	# (LOGIKA INI TIDAK SAYA UBAH)
	return player_node != null and is_instance_valid(player_node)


# --- Fungsi damage & kematian ---
func take_damage(amount):
	# (LOGIKA INI TIDAK SAYA UBAH)
	if health <= 0:
		return

	health -= amount
	print("Virus HP: ", health)
	
	if health <= 0:
		die()

func die():
	# (LOGIKA INI TIDAK SAYA UBAH)
	set_physics_process(false)
	velocity = Vector2.ZERO
	$CollisionShape2D.disabled = true
	$AttackRange.monitoring = false
	animated_sprite.play("dead")
	await get_tree().create_timer(1.0).timeout
	queue_free()


# --- Fungsi serangan (trigger dari area AttackRange) ---
func _on_attack_range_body_entered(body):
	# (LOGIKA INI TIDAK SAYA UBAH)
	if body.is_in_group("player"):
		print("💥 Virus menyerang player!")
		if body.has_method("take_damage"):
			body.take_damage(1)
