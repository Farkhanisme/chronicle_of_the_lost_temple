extends Control

# Pastikan path scene level pertama Anda benar
var level_pertama = "res://scene/test/test_scene_tilemap.tscn"

func _ready():
	# Menghubungkan signal tombol secara otomatis
	$Button/VBoxContainer/StartButton.pressed.connect(_on_start_pressed)
	#$CenterContainer/VBoxContainer/QuitButton.pressed.connect(_on_quit_pressed)

func _on_start_pressed():
	# Pindah ke scene permainan
	get_tree().change_scene_to_file("res://scene/test/test_scene_tilemap.tscn")

func _on_quit_pressed():
	# Keluar dari game
	get_tree().quit()


func _on_start_button_pressed() -> void:
	pass # Replace with function body.
