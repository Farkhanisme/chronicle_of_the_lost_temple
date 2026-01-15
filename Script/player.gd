extends CharacterBody2D

# 1. REFERENSI NODE
@onready var ANIM_PLAYER = $Body_Sprite
@onready var ANIM_HAIR = $Hair_Sprite
@onready var ANIM_TOOL = $Tool_Sprite
@onready var SHOVEL_POINT = $ShovelPoint 
@onready var BAR_ANIMASI = $BarAnimasi

@export var TILE_MAP : TileMapLayer 

# 2. VARIABEL STATUS
var is_shoveling = false
@export var move_speed = 150.0 

# --- VARIABEL BARU UNTUK HITUNGAN PACUL ---
var hits_required = 3      # Berapa kali pacul agar tanah berubah? (Ganti angka ini sesuka hati)
var current_hits = 0       # Menghitung sudah berapa kali pacul saat ini
var last_dig_pos = Vector2i.ZERO # Mengingat lokasi tanah terakhir yang dipacul

func _ready() -> void:
	if TILE_MAP == null:
		print("!!! ERROR: TILE_MAP BELUM DI-ASSIGN DI INSPECTOR !!!")
	
	if not ANIM_PLAYER.animation_finished.is_connected(_on_body_sprite_animation_finished):
		ANIM_PLAYER.animation_finished.connect(_on_body_sprite_animation_finished)

	if ANIM_PLAYER.sprite_frames.has_animation("menyekop"):
		ANIM_PLAYER.sprite_frames.set_animation_loop("menyekop", false)
		ANIM_HAIR.sprite_frames.set_animation_loop("menyekop", false)
		ANIM_TOOL.sprite_frames.set_animation_loop("menyekop", false)

	BAR_ANIMASI.hide()
	
# Misalkan batas map Anda adalah X: 0-2000 dan Y: 0-1000
var limit_min = Vector2(-247, 618)
var limit_max = Vector2(-136, 392)

func _process(_delta: float) -> void:
	if is_shoveling:
		return 

	# 3. LOGIKA INPUT MENYEKOP
	if Input.is_key_pressed(KEY_SPACE):
		start_shoveling()
		return

	# 4. LOGIKA ANIMASI JALAN / DIAM
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
	if not is_shoveling:
		var direction = Vector2.ZERO
		if Input.is_key_pressed(KEY_A): direction.x -= 1
		if Input.is_key_pressed(KEY_D): direction.x += 1
		if Input.is_key_pressed(KEY_W): direction.y -= 1
		if Input.is_key_pressed(KEY_S): direction.y += 1
		
		velocity = direction.normalized() * move_speed
		
		if velocity.length() > 0:
			current_hits = 0
			last_dig_pos = Vector2i.ZERO
			BAR_ANIMASI.hide() 
		else:
			velocity = Vector2.ZERO 
			
	# Pindahkan move_and_slide ke sini
	move_and_slide()
	
	limit_min = Vector2(-236, -126)
	limit_max = Vector2(610, 384)
	
	# Kunci posisi karakter TEPAT setelah move_and_slide
	# Gunakan nilai yang masuk akal (Min harus lebih kecil dari Max)
	global_position.x = clamp(global_position.x, limit_min.x, limit_max.x)
	global_position.y = clamp(global_position.y, limit_min.y, limit_max.y)

# --- FUNGSI AKSI ---

func start_shoveling():
	is_shoveling = true
	velocity = Vector2.ZERO 
	play_all_animations("menyekop")
	
	# Panggil logika interaksi
	check_tile_interaction()

func check_tile_interaction():
	if TILE_MAP == null: return  
		
	var local_pos = TILE_MAP.to_local(SHOVEL_POINT.global_position)
	var map_pos = TILE_MAP.local_to_map(local_pos)
	var atlas_coords = TILE_MAP.get_cell_atlas_coords(map_pos)
	
	var TAHAP_1 = Vector2i(50, 12) 
	var TAHAP_2 = Vector2i(50, 13) 
	var TAHAP_3 = Vector2i(50, 15) 
	
	# 1. Validasi Tanah
	if atlas_coords != TAHAP_1 and atlas_coords != TAHAP_2 and atlas_coords != TAHAP_3:
		BAR_ANIMASI.hide()
		current_hits = 0
		return 

	# 2. Munculkan & Posisikan Bar
	BAR_ANIMASI.show()
	var tile_global_pos = TILE_MAP.to_global(TILE_MAP.map_to_local(map_pos))
	BAR_ANIMASI.global_position = tile_global_pos + Vector2(0, -20) 

	# 3. Reset jika pindah lokasi
	if map_pos != last_dig_pos:
		current_hits = 0
		last_dig_pos = map_pos

	current_hits += 1
	
	# 4. Update Visual Bar (Frame 0-6)
	var total_frames = BAR_ANIMASI.sprite_frames.get_frame_count("loading")
	var frame_index = int(float(current_hits) / 9 * (total_frames - 1))
	BAR_ANIMASI.frame = clampi(frame_index, 0, total_frames - 1)

	# 5. Logika Perubahan Tanah
	var source_id = TILE_MAP.get_cell_source_id(map_pos)
	
	if current_hits == 3:
		if atlas_coords == TAHAP_1:
			TILE_MAP.set_cell(map_pos, source_id, TAHAP_2)
			
	elif current_hits == 6:
		if atlas_coords == TAHAP_2:
			TILE_MAP.set_cell(map_pos, source_id, TAHAP_3)
			
	elif current_hits >= 9:
		if atlas_coords == TAHAP_3:
			# Tampilkan frame terakhir dulu (Frame 6)
			BAR_ANIMASI.frame = total_frames - 1 
			
			# Hilangkan gundukan tanah
			TILE_MAP.set_cell(map_pos, -1)
			
			# TUNGGU SEBENTAR (misal 0.3 detik) sebelum menyembunyikan Bar
			# Agar pemain sempat melihat bar penuh (Frame 6)
			await get_tree().create_timer(0.3).timeout
			
			# Baru sembunyikan bar dan reset hitungan
			BAR_ANIMASI.hide()
			current_hits = 0

# --- FUNGSI PEMBANTU ---
func play_all_animations(anim_name: String):
	if ANIM_PLAYER.animation == anim_name and ANIM_PLAYER.is_playing():
		return
	ANIM_PLAYER.play(anim_name)
	ANIM_HAIR.play(anim_name)
	ANIM_TOOL.play(anim_name)

func set_all_flip(is_flipped: bool):
	ANIM_PLAYER.flip_h = is_flipped
	ANIM_HAIR.flip_h = is_flipped
	ANIM_TOOL.flip_h = is_flipped
	
	if is_flipped:
		SHOVEL_POINT.position.x = -abs(SHOVEL_POINT.position.x)
	else:
		SHOVEL_POINT.position.x = abs(SHOVEL_POINT.position.x)

func _on_body_sprite_animation_finished() -> void:
	if ANIM_PLAYER.animation == "menyekop":
		is_shoveling = false
		play_all_animations("idle")
