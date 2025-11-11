extends Control

func _on_proceed_pressed():
	# Naikkan stage dan kembali ke Game
	GameManager.current_stage += 1
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


