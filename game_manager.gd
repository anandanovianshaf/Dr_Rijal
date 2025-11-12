extends Node

# Stage saat ini. Kita bisa ubah ini nanti saat pindah level
# Untuk tes, kita bisa ganti manual angkanya (1, 2, atau 3)
var current_stage: int = 1

# Fungsi ini adalah "database" kesulitan kita.
# Script lain (player) akan memanggil fungsi ini.
func get_current_stage_settings() -> Dictionary:
	# Kita pakai 'match' (seperti 'switch' di bahasa lain)
	match current_stage:
		1:
			# Stage 1: 4 panah, 4 detik, 3 detik cooldown
			return {
				"arrow_count": 4,
				"input_time": 3.0,
				"cooldown_time": 2.0,
				"max_enemies": 6
			}
		2:
			# Stage 2: 6 panah, 4 detik, 4 detik cooldown
			return {
				"arrow_count": 6,
				"input_time": 4.0,
				"cooldown_time": 3.0,
				"max_enemies": 8
			}
		3:
			# Stage 3: 8 panah, 3 detik, 4 detik cooldown
			return {
				"arrow_count": 8,
				"input_time": 3.0,
				"cooldown_time": 4.0,
				"max_enemies": 11
			}
		_:
			# Default, jika 'current_stage' di-set ke angka aneh
			# Kita samakan saja dengan Stage 1
			return {
				"arrow_count": 4,
				"input_time": 4.0,
				"cooldown_time": 3.0,
				"max_enemies": 4
			}
