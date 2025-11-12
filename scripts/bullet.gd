extends Area2D

# --- PROPERTI (TIDAK BERUBAH) ---
@export var speed: float = 600.0
var target: Node2D = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@export var max_lifetime := 3.0

# --- TAMBAHAN 1: PRELOAD KOSTUM PELURU ---
# (Pastikan path .tres Anda sudah benar)
var peluru1_frames = preload("res://assets/peluru capsule/Bullet1.tres")
var peluru2_frames = preload("res://assets/peluru capsule/Bullet2.tres")
var peluru3_frames = preload("res://assets/peluru capsule/Bullet3.tres")
# --- AKHIR TAMBAHAN 1 ---


func _ready():
	# --- TAMBAHAN 2: LOGIKA GANTI KOSTUM ---
	# Kita tunggu 1 frame dulu agar GameManager 100% siap
	await get_tree().process_frame 
	
	# Cek stage saat ini
	match GameManager.current_stage:
		3:
			animated_sprite.sprite_frames = peluru3_frames
		2:
			animated_sprite.sprite_frames = peluru2_frames
		_: # Default (Stage 1)
			animated_sprite.sprite_frames = peluru1_frames
	
	# Pastikan animasi "fly" diputar setelah ganti kostum
	animated_sprite.play("fly")
	# --- AKHIR TAMBAHAN 2 ---

	# Logika max_lifetime Anda (TIDAK BERUBAH)
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func _physics_process(delta):
	# (LOGIKA INI TIDAK SAYA UBAH)
	if not target or not is_instance_valid(target):
		queue_free()
		return
		
	var direction = (target.global_position - global_position).normalized()
	global_position += direction * speed * delta
	rotation = direction.angle()

# (Fungsi ini TIDAK SAYA UBAH)
func _on_body_entered(body):
	print("💥 Bullet hit: ", body.name)
	if not is_instance_valid(body):
		return

	if body.is_in_group("virus"):
		speed = 0
		collision_shape.disabled = true

		animated_sprite.play("explode")

		if body.has_method("take_damage"):
			body.take_damage(100)
	else:
		print("⚠️ Peluru menabrak objek bukan virus: ", body.name)
		
# (Fungsi ini TIDAK SAYA UBAH)
func _on_animated_sprite_animation_finished():
	if animated_sprite.animation == "explode":
		queue_free()

# --- CATATAN ---
# Fungsi di bawah ini sepertinya duplikat (mungkin dari
# Godot yang otomatis menghubungkan sinyal).
# Anda mungkin bisa menghapusnya jika tidak terpakai.
func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
