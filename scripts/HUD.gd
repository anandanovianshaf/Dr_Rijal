extends Control

# 1. Siapkan "remote control" ke 3 kantong darah

@onready var hp1 = $HealthContainer/HP1
@onready var hp2 = $HealthContainer/HP2
@onready var hp3 = $HealthContainer/HP3

# 2. Godot otomatis membuat fungsi ini untuk Anda
#    saat Anda menghubungkan sinyal di Langkah 3.
#    Fungsi ini akan berjalan SETIAP kali 'health_changed' dipancarkan.
func _on_player_health_changed(new_health: int):
	await get_tree().process_frame
	# 'match' adalah cara keren untuk menggantikan banyak 'if'
	match new_health:
		3:
			# HP penuh
			hp1.visible = true
			hp2.visible = true
			hp3.visible = true
		2:
			# Kena 1x
			hp1.visible = true
			hp2.visible = true
			hp3.visible = false # Sembunyikan kantong ke-3
		1:
			# Kena 2x
			hp1.visible = true
			hp2.visible = false # Sembunyikan kantong ke-2
			hp3.visible = false
		_:
			# Untuk 0 atau lainnya (mati)
			hp1.visible = false # Sembunyikan semua
			hp2.visible = false
			hp3.visible = false
