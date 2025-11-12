extends Area2D

# Kecepatan peluru, bisa diatur
@export var speed: float = 600.0

# Target yang akan dikejar (akan di-set oleh Player)
var target: Node2D = null

@onready var animated_sprite = $AnimatedSprite2D
@onready var collision_shape = $CollisionShape2D
@export var max_lifetime := 3.0

func _ready():
	await get_tree().create_timer(max_lifetime).timeout
	queue_free()

func _physics_process(delta):
	# 1. Cek keamanan: Jika target sudah tidak ada (mati), hancurkan diri sendiri
	if not target or not is_instance_valid(target):
		queue_free()
		return
		
	# 2. Logika Homing (Mengejar)
	# Hitung arah dari peluru ke target
	var direction = (target.global_position - global_position).normalized()
	# Gerakkan peluru ke arah itu
	global_position += direction * speed * delta
	
	# (Opsional) Buat peluru berputar menghadap target
	rotation = direction.angle()

# --- HUBUNGKAN SINYAL-SINYAL INI DI EDITOR ---

# 1. Hubungkan Sinyal "body_entered" dari node 'Peluru' (Area2D)
func _on_body_entered(body):
	print("💥 Bullet hit: ", body.name)
	if not is_instance_valid(body):
		return

	# Cek apakah ini virus
	if body.is_in_group("virus"):
		speed = 0
		collision_shape.disabled = true

		# Jalankan animasi ledakan
		animated_sprite.play("explode")

		# Beri damage ke virus
		if body.has_method("take_damage"):
			body.take_damage(100)
	else:
		print("⚠️ Peluru menabrak objek bukan virus: ", body.name)
		


# 2. Hubungkan Sinyal "animation_finished" dari node 'AnimatedSprite2D'
func _on_animated_sprite_animation_finished():
	# Jika animasi yang selesai adalah "explode"...
	if animated_sprite.animation == "explode":
		# ...hancurkan diri sendiri
		queue_free()


func _on_animated_sprite_2d_animation_finished() -> void:
	pass # Replace with function body.
