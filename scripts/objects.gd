extends StaticBody2D

func init(tex: Texture, px_size: Vector2, pos: Vector2):
	# sprite
	$Sprite2D.texture = tex
	$Sprite2D.scale = Vector2(1,1)   # sesuaikan bila perlu
	# collision
	var rect = RectangleShape2D.new()
	rect.size = px_size
	$CollisionShape2D.shape = rect
	# posisi di world
	global_position = pos
