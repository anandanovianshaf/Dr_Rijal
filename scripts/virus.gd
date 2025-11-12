extends CharacterBody2D

@export var speed: float = 75.0
@export var health: int = 5
@export var stopping_distance: float = 24.0
@export var virus_scale: Vector2 = Vector2(0.6, 0.6)

@onready var animated_sprite = $AnimatedSprite2D
var player_node: Node2D = null


func _ready():
	# Tunggu 1 frame agar semua node (termasuk Player) sudah siap
	await get_tree().process_frame
	_find_player()
	animated_sprite.play("walk")
	# Kurangi safe margin untuk menghindari dorong-mendorong berlebih
	safe_margin = 0.01
	scale = virus_scale

func _physics_process(_delta):
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
	# Coba cari Player lewat struktur scene dulu
	if get_parent().has_node("Player"):
		player_node = get_parent().get_node("Player")
	else:
		# Jika gagal, fallback ke group 'player'
		player_node = get_tree().get_first_node_in_group("player")

func _is_player_valid() -> bool:
	return player_node != null and is_instance_valid(player_node)


# --- Fungsi damage & kematian ---
func take_damage(amount):
	# Kita cek dulu apakah health masih ada
	# (agar tidak memanggil die() berkali-kali)
	if health <= 0:
		return

	health -= amount
	print("Virus HP: ", health)
	
	if health <= 0:
		die()

func die():
	# 1. Hentikan semua logika AI
	set_physics_process(false)
	velocity = Vector2.ZERO
	
	# 2. Matikan semua tabrakan
	$CollisionShape2D.disabled = true
	$AttackRange.monitoring = false
	
	# 3. Putar animasi mati
	# (Pastikan Anda punya animasi "dead" di Virus.tscn)
	animated_sprite.play("dead")
	
	# 4. Tunggu 1 detik (agar animasi sempat main)
	await get_tree().create_timer(1.0).timeout
	
	# 5. Hapus virus
	queue_free()


# --- Fungsi serangan (trigger dari area AttackRange) ---
func _on_attack_range_body_entered(body):
	if body.is_in_group("player"):
		print("💥 Virus menyerang player!")
		if body.has_method("take_damage"):
			body.take_damage(1)
