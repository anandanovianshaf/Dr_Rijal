extends Area2D

# 1. Siapkan 'remote control' ke node-node anak
@onready var sprite = $Sprite
@onready var collision_shape = $CollisionShape2D
@onready var respawn_timer = $RespawnTimer

# Variabel untuk menandakan potion "disembunyikan"
var is_collected = false

func _ready():
	# 2. Hubungkan sinyal-sinyal
	# Saat ada body masuk ke Area2D
	self.body_entered.connect(_on_body_entered)
	# Saat timer 10 detik selesai
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)

func _on_body_entered(body):
	# 3. Cek apakah yang masuk adalah Player DAN potion belum diambil
	if body.is_in_group("player") and not is_collected:
		
		# 4. Beri tahu Player untuk mencoba heal
		# Kita tidak peduli HP-nya penuh atau tidak.
		# Player.gd yang akan mengurus logika "HP Penuh".
		if body.has_method("heal"):
			body.heal(1) # Coba sembuhkan 1 HP
			
		# 5. Kumpulkan Potion
		_collect()

func _collect():
	# Fungsi ini menyembunyikan potion dan memulai timer
	is_collected = true
	sprite.visible = false
	collision_shape.set_deferred("disabled", true) # Matikan sensor (cara aman)
	respawn_timer.start() # Mulai hitungan 10 detik
	
	print("Potion diambil! Respawn dalam 10 detik...")

func _on_respawn_timer_timeout():
	# Fungsi ini dipanggil setelah 10 detik
	is_collected = false
	sprite.visible = true
	collision_shape.set_deferred("disabled", false) # Nyalakan sensor lagi
	
	print("Potion respawn!")
