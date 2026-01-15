extends ParallaxBackground

# Kecepatan & Arah angin (X = Horizontal, Y = Vertikal)
var cloud_speed = Vector2(15.0, 10.0) 

func _process(delta: float) -> void:
	# Geser offset background terus menerus setiap frame
	scroll_offset += cloud_speed * delta
