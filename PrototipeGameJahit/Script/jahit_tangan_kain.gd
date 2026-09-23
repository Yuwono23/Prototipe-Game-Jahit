extends Control

signal minigame_selesai(sukses: bool)

@onready var timer_game = $Timer
@onready var bar_waktu = $ProgressBar
@onready var wadah_titik = $WadahTitik
@onready var garis_pemain = $GarisPemain

@export var durasi_waktu: float = 10.0
@export var radius_toleransi: float = 50.0 # Seberapa jauh jari meleset dari titik tapi masih dianggap kena

var daftar_titik: Array[Vector2] = []
var indeks_target_sekarang: int = 0
var sedang_dijahit: bool = false
var game_aktif: bool = false
# Tambahkan referensi ini di bagian atas bersama variabel @onready lainnya
@onready var garis_petunjuk = $GarisPetunjuk 

func _ready():
	timer_game.timeout.connect(_kalah)
	
	# Bersihkan garis bawaan (jika ada) saat game dimulai
	garis_pemain.clear_points()
	garis_petunjuk.clear_points() # Bersihkan petunjuk juga
	
	# --- [KODE BARU KODI: Setting Garis Petunjuk] ---
	garis_petunjuk.texture = _buat_tekstur_putus()
	garis_petunjuk.texture_mode = Line2D.LINE_TEXTURE_TILE
	
	# INI KUNCI UTAMANYA: Mengaktifkan pengulangan tekstur (tiling)
	garis_petunjuk.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED 
	
	garis_petunjuk.width = 20 
	garis_petunjuk.default_color = Color(1.0, 1.0, 1.0, 1.0) # Kembalikan ke Putih agar tidak menimpa warna tekstur
	# ------------------------------------------------
	
	# 1. Simpan koordinat dan GAMBAR garis petunjuk sekaligus
	for titik in wadah_titik.get_children():
		daftar_titik.append(titik.global_position)
		garis_petunjuk.add_point(titik.global_position) 
		
	_mulai_minigame()

func _mulai_minigame():
	bar_waktu.max_value = durasi_waktu
	timer_game.start(durasi_waktu)
	game_aktif = true
	indeks_target_sekarang = 0
	
	# Tambahkan titik awal benang di Titik0
	garis_pemain.add_point(daftar_titik[0])

func _process(_delta):
	if game_aktif:
		bar_waktu.value = timer_game.time_left

func _input(event):
	if not game_aktif: return
	
	# Cek jenis input (klik/sentuh awal, tahan/geser, lepas)
	var sentuh_mulai = event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.pressed)
	var sentuh_lepas = event.is_action_released("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.is_pressed()) or (event is InputEventScreenTouch and not event.pressed)
	
	# Ambil posisi kursor/jari
	var posisi_input = Vector2.ZERO
	if event is InputEventMouse:
		posisi_input = event.global_position
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		posisi_input = event.position

	# --- LOGIKA MENARIK BENANG ---
	
	# 1. Saat pemain mulai menyentuh layar
	if sentuh_mulai:
		# Pastikan jarinya menyentuh di dekat titik target yang sedang aktif
		var jarak_ke_target = posisi_input.distance_to(daftar_titik[indeks_target_sekarang])
		if jarak_ke_target <= radius_toleransi:
			sedang_dijahit = true
			
			# Tambahkan titik melayang pada Line2D yang akan mengikuti jari
			if garis_pemain.get_point_count() == indeks_target_sekarang + 1:
				garis_pemain.add_point(posisi_input)
				
	# 2. Saat pemain menggeser jarinya
	elif (event is InputEventMouseMotion or event is InputEventScreenDrag) and sedang_dijahit:
		# Perbarui posisi ujung benang agar nempel dengan jari
		garis_pemain.set_point_position(garis_pemain.get_point_count() - 1, posisi_input)
		
		# Cek apakah ujung benang sudah menabrak titik tujuan berikutnya
		var indeks_tujuan_berikutnya = indeks_target_sekarang + 1
		if indeks_tujuan_berikutnya < daftar_titik.size():
			var jarak_ke_tujuan = posisi_input.distance_to(daftar_titik[indeks_tujuan_berikutnya])
			
			if jarak_ke_tujuan <= radius_toleransi:
				# KUNCI BENANG! (Pemain berhasil menyambungkan titik)
				garis_pemain.set_point_position(garis_pemain.get_point_count() - 1, daftar_titik[indeks_tujuan_berikutnya])
				indeks_target_sekarang += 1
				
				# Cek apakah ini titik terakhir (Menang)
				if indeks_target_sekarang == daftar_titik.size() - 1:
					_menang()
				else:
					# Jika belum selesai, langsung siapkan titik baru untuk ditarik ke titik selanjutnya
					garis_pemain.add_point(daftar_titik[indeks_target_sekarang])
					
	# 3. Saat pemain melepas jarinya (gagal menyambung)
	elif sentuh_lepas:
		if sedang_dijahit:
			sedang_dijahit = false
			# Jika dilepas di tengah jalan (belum sampai titik berikutnya), tarik kembali benangnya
			if garis_pemain.get_point_count() > indeks_target_sekarang + 1:
				garis_pemain.remove_point(garis_pemain.get_point_count() - 1)

func _menang():
	game_aktif = false
	sedang_dijahit = false
	timer_game.stop()
	print("Jahitan Sempurna!")
	minigame_selesai.emit(true)

func _kalah():
	game_aktif = false
	sedang_dijahit = false
	print("Waktu Habis! Jahitan gagal.")
	minigame_selesai.emit(false)

# Fungsi untuk menggambar tekstur garis putus-putus (dash) secara otomatis
func _buat_tekstur_putus() -> Texture2D:
	# Membuat kanvas kosong berukuran panjang 64px dan lebar 16px
	var gambar = Image.create(64, 16, false, Image.FORMAT_RGBA8)
	
	# Mewarnai kanvas: setengah kiri diisi warna, setengah kanan dibiarkan transparan
	for x in range(64):
		for y in range(16):
			if x < 32:
				gambar.set_pixel(x, y, Color(0.0, 0.0, 0.0, 1.0)) # Warna putih sedikit transparan
			else:
				gambar.set_pixel(x, y, Color(0.0, 0.0, 0.0, 0.0)) # Transparan penuh (tembus pandang)
				
	return ImageTexture.create_from_image(gambar)
