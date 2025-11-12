# Ganti path "res://scripts/game.gd" jika nama/lokasi script game.gd Anda berbeda
# INI ADALAH SATU-SATUNYA BARIS 'extends' YANG ANDA BUTUHKAN
extends "res://scripts/game.gd" 

# Kita tidak perlu 'extends Node2D' lagi


func _ready():
	# --- INI KUNCINYA ---
	# Beri tahu GameManager bahwa kita sekarang di stage 2
	GameManager.current_stage = 2
	# --- AKHIR KUNCI ---
	
	# Jalankan _ready() orisinal dari 'game.gd' (induknya)
	# (Ini akan menghubungkan sinyal HP, kamera, dll. secara otomatis)
	super._ready()
