extends CharacterBody2D

# 1. REFERENSI NODE
@onready var ANIM_PLAYER = $Body_Sprite
@onready var ANIM_HAIR = $Hair_Sprite
@onready var ANIM_TOOL = $Tool_Sprite
# Pastikan Anda menambahkan node Marker2D bernama ShovelPoint sebagai anak Player
@onready var SHOVEL_POINT = $ShovelPoint 
# Pastikan nama TileMap di luar sama dengan yang tertulis di sini
@onready var TILE_MAP = get_parent().get_node("TileMap") 

# 2. VARIABEL STATUS
var is_shoveling = false
var move_speed = 150.0 # Anda bisa sesuaikan kecepatannya

func _ready() -> void:
	# Mematikan loop lewat kode agar sistem 'is_shoveling' bekerja dengan benar
	if ANIM_PLAYER.sprite_frames.has_animation("menyekop"):
		ANIM_PLAYER.sprite_frames.set_animation_loop("menyekop", false)
		ANIM_HAIR.sprite_frames.set_animation_loop("menyekop", false)
		ANIM_TOOL.sprite_frames.set_animation_loop("menyekop", false)

func _process(_delta: float) -> void:
	# 3. LOGIKA INPUT MENYEKOP (TAHAN UNTUK TERUS MENYEKOP)
	# Pastikan "menyekop" ada di Input Map (Klik Kiri)
	if Input.is_action_pressed("menyekop") and not is_shoveling:
		start_shoveling()

	# 4. LOGIKA ANIMASI JALAN / DIAM
	if not is_shoveling:
		if velocity.length() > 0:
			play_all_animations("walk")
		else:
			play_all_animations("idle")
	
	# 5. LOGIKA FLIP ARAH
	if Input.is_key_pressed(KEY_A):
		set_all_flip(true)
	elif Input.is_key_pressed(KEY_D):
		set_all_flip(false)

func _physics_process(_delta: float) -> void:
	# 6. LOGIKA PERGERAKAN
	if not is_shoveling:
		var direction = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
		# Jika tidak pakai Input Map bawaan, gunakan ini:
		direction = Vector2.ZERO
		if Input.is_key_pressed(KEY_A): direction.x -= 1
		if Input.is_key_pressed(KEY_D): direction.x += 1
		if Input.is_key_pressed(KEY_W): direction.y -= 1
		if Input.is_key_pressed(KEY_S): direction.y += 1
		
		velocity = direction.normalized() * move_speed
	else:
		velocity = Vector2.ZERO # Berhenti saat menyekop
		
	move_and_slide()

# --- FUNGSI AKSI ---

func start_shoveling():
	is_shoveling = true
	play_all_animations("menyekop")
	check_tile_interaction()

func check_tile_interaction():
	if TILE_MAP:
		var local_pos = TILE_MAP.to_local(SHOVEL_POINT.global_position)
		var map_pos = TILE_MAP.local_to_map(local_pos)
		
		# Ambil koordinat tile saat ini
		var atlas_coords = TILE_MAP.get_cell_atlas_coords(map_pos)
		
		# TENTUKAN KOORDINAT ATLAS ANDA DI SINI
		var TAHAP_1 = Vector2i(50, 12) # Contoh: Gundukan Paling Besar
		var TAHAP_2 = Vector2i(50, 13) # Contoh: Gundukan Sedang
		var TAHAP_3 = Vector2i(50, 15) # Contoh: Gundukan Kecil
		
		# LOGIKA TAHAPAN (Satu klik ganti satu tahap)
		if atlas_coords == TAHAP_1:
			# Ganti ke Tahap 2
			TILE_MAP.set_cell(map_pos, 0, TAHAP_2)
			#print("Gundukan besar jadi sedang")
			
		elif atlas_coords == TAHAP_2:
			# Ganti ke Tahap 3
			TILE_MAP.set_cell(map_pos, 0, TAHAP_3)
			#print("Gundukan sedang jadi kecil")
			
		elif atlas_coords == TAHAP_3:
			# Tahap terakhir, maka hilangkan
			TILE_MAP.set_cell(map_pos, -1)
			#print("Gundukan hilang!")

# --- FUNGSI PEMBANTU ---
func play_all_animations(anim_name: String):
	if ANIM_PLAYER.animation != anim_name:
		ANIM_PLAYER.play(anim_name)
		ANIM_HAIR.play(anim_name)
		ANIM_TOOL.play(anim_name)

func set_all_flip(is_flipped: bool):
	ANIM_PLAYER.flip_h = is_flipped
	ANIM_HAIR.flip_h = is_flipped
	ANIM_TOOL.flip_h = is_flipped
	
	# Memindahkan posisi deteksi sekop agar mengikuti arah hadap
	if is_flipped:
		SHOVEL_POINT.position.x = -15 # Sesuaikan angka ini dengan posisi sekop kiri
	else:
		SHOVEL_POINT.position.x = 15  # Sesuaikan angka ini dengan posisi sekop kanan

# --- KONEKSI SIGNAL ---
# Pastikan Anda menyambungkan signal animation_finished dari Body_Sprite ke sini
func _on_body_sprite_animation_finished() -> void:
	if ANIM_PLAYER.animation == "menyekop":
		is_shoveling = false
