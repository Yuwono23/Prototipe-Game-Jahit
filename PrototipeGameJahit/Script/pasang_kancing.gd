extends Control

signal minigame_selesai(sukses: bool)

enum Arah { ATAS, BAWAH, KIRI, KANAN }

@onready var timer_game = $Timer
@onready var bar_waktu = $ProgressBar
@onready var panah_target = $WadahPanah/PanahTarget.get_children() # Mengambil 4 TextureRect target
@onready var panah_pemain = $WadahPanah/PanahPemain.get_children() # Mengambil 4 TextureRect pemain

# Masukkan tekstur panah milikmu dari Inspector
@export var tekstur_hitam_atas: Texture2D
@export var tekstur_putih_atas: Texture2D

@export var total_ronde: int = 3
@export var durasi_waktu: float = 15.0

var ronde_saat_ini: int = 0
var urutan_target: Array[Arah] = []
var indeks_input_sekarang: int = 0
var game_aktif: bool = false

# Variabel Swipe
var posisi_awal_swipe: Vector2
var sedang_swipe: bool = false
var minimal_jarak_swipe: float = 60.0 # Seberapa jauh jari harus bergeser agar terhitung usapan

func _ready():
	timer_game.timeout.connect(_kalah)
	_mulai_minigame()

func _mulai_minigame():
	ronde_saat_ini = 0
	bar_waktu.max_value = durasi_waktu
	timer_game.start(durasi_waktu)
	game_aktif = true
	_buat_ronde_baru()

func _process(_delta):
	if game_aktif:
		bar_waktu.value = timer_game.time_left

func _buat_ronde_baru():
	indeks_input_sekarang = 0
	urutan_target.clear()
	
	# Bersihkan panah kuning pemain di layar
	for kotak_pemain in panah_pemain:
		kotak_pemain.texture = null
		
	# [KODE BARU KODI] Tunggu 1 frame agar ukuran kotak UI selesai dihitung
	await get_tree().process_frame
		
	# Buat 4 arah acak untuk target
	for i in range(4):
		var arah_acak = Arah.values()[randi() % Arah.size()]
		urutan_target.append(arah_acak)
		
		# Setel gambar dan rotasi panah target
		var kotak_target = panah_target[i] as TextureRect
		kotak_target.texture = tekstur_hitam_atas # Variabel tempat panah biru
		kotak_target.pivot_offset = kotak_target.size / 2.0
		kotak_target.rotation_degrees = _dapatkan_derajat_rotasi(arah_acak)

# --- DETEKSI SWIPE (USAPAN LENGKAP) ---
func _input(event):
	if not game_aktif: return
	
	# 1. Mendeteksi awal sentuhan/klik
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.is_pressed():
			sedang_swipe = true
			posisi_awal_swipe = event.position
		else:
			sedang_swipe = false # Dilepas sebelum mencapai jarak minimum
			
	# 2. Mendeteksi geseran
	elif event is InputEventScreenDrag or event is InputEventMouseMotion:
		if sedang_swipe:
			var vektor_geser = event.position - posisi_awal_swipe
			# Jika geseran sudah cukup jauh, proses arahnya dan hentikan deteksi sampai klik berikutnya
			if vektor_geser.length() > minimal_jarak_swipe:
				_proses_arah_swipe(vektor_geser)
				sedang_swipe = false 

func _proses_arah_swipe(vektor_swipe: Vector2):
	var arah_usapan: Arah
	
	# Cek apakah usapan lebih condong horizontal atau vertikal
	if abs(vektor_swipe.x) > abs(vektor_swipe.y):
		arah_usapan = Arah.KANAN if vektor_swipe.x > 0 else Arah.KIRI
	else:
		arah_usapan = Arah.BAWAH if vektor_swipe.y > 0 else Arah.ATAS
		
	_cek_jawaban(arah_usapan)

func _cek_jawaban(arah_ditebak: Arah):
	if arah_ditebak == urutan_target[indeks_input_sekarang]:
		# JAWABAN BENAR
		var kotak_pemain = panah_pemain[indeks_input_sekarang] as TextureRect
		kotak_pemain.texture = tekstur_putih_atas # Variabel tempat panah kuning
		
		# Pastikan poros berada di tengah sebelum diputar
		kotak_pemain.pivot_offset = kotak_pemain.size / 2.0 
		kotak_pemain.rotation_degrees = _dapatkan_derajat_rotasi(arah_ditebak)
		
		indeks_input_sekarang += 1
		
		# Cek apakah ronde ini selesai
		if indeks_input_sekarang >= 4:
			ronde_saat_ini += 1
			if ronde_saat_ini >= total_ronde:
				_menang()
			else:
				game_aktif = false
				await get_tree().create_timer(0.5).timeout
				game_aktif = true
				_buat_ronde_baru()
	else:
		# JAWABAN SALAH (Layar Bergetar & Reset Input Ronde)
		_layar_bergetar()
		
		indeks_input_sekarang = 0
		for kotak_pemain in panah_pemain:
			kotak_pemain.texture = null

func _layar_bergetar():
	# Menggetarkan seluruh layar minigame (menggunakan Tween)
	var posisi_asli = position
	var tween = create_tween().set_trans(Tween.TRANS_SINE)
	
	for i in range(4):
		var getar_x = randf_range(-15, 15)
		tween.tween_property(self, "position:x", posisi_asli.x + getar_x, 0.05)
	tween.tween_property(self, "position:x", posisi_asli.x, 0.05)

# Fungsi memutar gambar yang aslinya menghadap KANAN
func _dapatkan_derajat_rotasi(arah: Arah) -> float:
	match arah:
		Arah.KANAN: return 0.0
		Arah.BAWAH: return 90.0
		Arah.KIRI: return 180.0
		Arah.ATAS: return 270.0
	return 0.0

func _menang():
	game_aktif = false
	timer_game.stop()
	print("Kancing Terpasang!")
	minigame_selesai.emit(true)

func _kalah():
	game_aktif = false
	print("Waktu Habis! Gagal menjahit kancing.")
	minigame_selesai.emit(false)
