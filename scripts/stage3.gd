extends "res://scripts/game.gd"   # INHERIT everything

func _ready() -> void:
	# Tell GameManager which stage we are
	GameManager.current_stage = 3
	# THEN run the base logic
	super._ready()
