extends TextureRect

# --- 1. SIAPKAN SEMUA GAMBAR ANGKA ---
#    Ganti 'path/to/...' dengan path file Anda yang sebenarnya.
#    Kita gunakan Dictionary agar rapi.
var number_textures = {
	1: preload("res://assets/numbers/no1.png"),
	2: preload("res://assets/numbers/no2.png"),
	3: preload("res://assets/numbers/no3.png"),
	4: preload("res://assets/numbers/no4.png"),
	5: preload("res://assets/numbers/no5.png"),
	# (Anda juga bisa tambahkan 0 jika perlu)
	# 0: preload("res://assets/numbers/0.png")
}

# --- 2. BUAT FUNGSI PUBLIK ---
# Ini adalah fungsi yang bisa "dipanggil"
# dari script lain untuk mengubah angka.

func set_number(num_to_show: int):
	# Cek apakah angka yang diminta ada di 'database' kita
	if number_textures.has(num_to_show):
		# Jika ada, ganti tekstur scene ini
		self.texture = number_textures[num_to_show]
		self.visible = true # Pastikan terlihat
	else:
		# Jika angka yang diminta tidak ada (misal 0 atau 6),
		# sembunyikan saja.
		self.visible = false
