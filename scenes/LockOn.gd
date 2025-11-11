extends Node2D

# Ambil node child-nya yang bernama AnimatedSprite2D
@onready var animated_sprite = $AnimatedSprite2D


func _ready():
	# Saat scene ini muncul, paksa "AnimatedSprite2D"
	# untuk memutar animasi yang bernama "lock"
	animated_sprite.play("lock")
