extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies_alive: int = 999
@export var spawn_distance: float = 800.0
@export var spawn_random_offset: float = 500.0

var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.wait_time = spawn_interval
	_timer.autostart = true
	_timer.timeout.connect(_on_spawn_timeout)
	add_child(_timer)
	

func _on_spawn_timeout():
	if not enemy_scene:
		return

	var max_limit := max_enemies_alive
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("get_current_stage_settings"):
		var settings := GameManager.get_current_stage_settings()
		if settings.has("max_enemies"):
			max_limit = int(settings.max_enemies)

	if _count_enemies() >= max_limit:
		return

	var spawn_pos = _get_spawn_position()

	# Spawn musuh baru
	var enemy = enemy_scene.instantiate()
	
	# 🔹 Atur ukuran acak antara 0.5x - 0.8x
	enemy.virus_scale = Vector2(0.6, 0.6)
	
	get_parent().add_child(enemy)
	enemy.global_position = spawn_pos


func _count_enemies() -> int:
	var count := 0
	for n in get_tree().get_nodes_in_group("virus"):
		if is_instance_valid(n):
			count += 1
	return count

func _get_spawn_position() -> Vector2:
	# 1. Dapatkan posisi Player
	var player: Node2D = get_parent().get_node_or_null("Player")
	
	# Fallback: Jika player tidak ada, spawn di (0,0)
	if player == null:
		return Vector2.ZERO

	# --- INI LOGIKA BARU YANG LEBIH BAIK ---

	# 2. Buat arah acak (lingkaran 360 derajat)
	# TAU adalah konstanta bawaan Godot untuk 2 * PI (satu lingkaran penuh)
	var random_angle = randf_range(0, TAU) 

	# 3. Buat jarak acak dalam "cincin"
	# Jarak minimal = spawn_distance (misal 800)
	# Jarak maksimal = spawn_distance + spawn_random_offset (misal 800 + 500 = 1300)
	var random_distance = randf_range(spawn_distance, spawn_distance + spawn_random_offset)
	
	# 4. Hitung posisi offset dari player
	# Vector2.RIGHT.rotated(random_angle) akan memberi kita
	# sebuah vektor arah acak (seperti jarum jam yang berputar)
	var offset_vector = Vector2.RIGHT.rotated(random_angle) * random_distance

	# 5. Posisi spawn final = posisi player + offset acak
	return player.global_position + offset_vector
