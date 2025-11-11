extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies_alive: int = 999
@export var spawn_distance: float = 600.0
@export var spawn_random_offset: float = 300.0

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
	var player: Node2D = get_parent().get_node_or_null("Player")
	if player == null:
		return Vector2.ZERO

	# Ambil kamera aktif di dunia (biasanya anak dari Player)
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return player.global_position + Vector2(randf_range(-spawn_distance, spawn_distance), -spawn_distance)

	# Hitung batas pandangan kamera dalam koordinat dunia
	var screen_size := get_viewport_rect().size * cam.zoom
	var cam_pos := cam.global_position

	var left := cam_pos.x - screen_size.x / 2
	var right := cam_pos.x + screen_size.x / 2
	var top := cam_pos.y - screen_size.y / 2
	var bottom := cam_pos.y + screen_size.y / 2

	# Tambahkan margin di luar layar agar spawn tidak kelihatan langsung
	var spawn_margin := 200.0  # bisa kamu ubah sesuai keadilan spawn
	var spawn_pos := Vector2.ZERO

	# Tentukan sisi mana untuk spawn: 0=atas, 1=kanan, 2=bawah, 3=kiri
	var side := randi() % 4
	match side:
		0:
			spawn_pos = Vector2(randf_range(left - spawn_margin, right + spawn_margin), top - spawn_margin)
		1:
			spawn_pos = Vector2(right + spawn_margin, randf_range(top - spawn_margin, bottom + spawn_margin))
		2:
			spawn_pos = Vector2(randf_range(left - spawn_margin, right + spawn_margin), bottom + spawn_margin)
		_:
			spawn_pos = Vector2(left - spawn_margin, randf_range(top - spawn_margin, bottom + spawn_margin))

	return spawn_pos
