extends Control
const HINT_OVERLAY_SCENE = preload("res://Scene/Hint.tscn") # Sesuaikan path file-mu

@onready var indikator = $UI_SkillCheck/IndikatorJarum
@onready var zona_hijau = $UI_SkillCheck/BackgroundBar/ZonaHijau
@onready var bg_bar = $UI_SkillCheck/BackgroundBar
@onready var gunting_besar = $VisualPotong/Kain/LintasanPola/PengikutJalur/GuntingBesar
@onready var kamera = $Kamera
@onready var wadah_centang = $UI_SkillCheck/WadahCentang
@onready var jalur_pola = $VisualPotong/Kain/LintasanPola
@onready var pengikut_jalur = $VisualPotong/Kain/LintasanPola/PengikutJalur
@onready var jejak_potongan = $VisualPotong/Kain/LintasanPola/JejakPotongan
@onready var kain_rect = $VisualPotong/Kain # Asumsi menggunakan TextureRect
@onready var timer_global = $TimerGlobal
@onready var latar_kain = $BackgroundKain
# Variabel yang bisa disesuaikan nilainya langsung di Inspector
@export var durasi_waktu: float = 10.0
signal minigame_selesai(sukses: bool)

var kecepatan_indikator = 500.0
var arah = 1
var batas_kiri = 0.0
var batas_kanan = 0.0
var target_progres = 3
var progres_saat_ini = 0

func _ready():
	if GlobalData.tekstur_kain_terpilih != null:
		latar_kain.texture = GlobalData.tekstur_kain_terpilih
	_buat_jalur_otomatis(kain_rect.texture)
	# Menentukan batas pantulan kiri dan kanan berdasarkan ukuran bar abu-abu
	batas_kiri = bg_bar.global_position.x
	batas_kanan = bg_bar.global_position.x + bg_bar.size.x - indikator.size.x
	
	jejak_potongan.clear_points()
	# Tambahkan titik awal tepat di ujung bawah gunting
	jejak_potongan.add_point(pengikut_jalur.position)
	
	# 1. Spawn Hint Overlay
	var hint = HINT_OVERLAY_SCENE.instantiate()
	add_child(hint)
	# 2. Tentukan Teks Instruksi untuk minigame ini (misal: "JAHIT!")
	hint.tampilkan_hint("POTONG SESUAI POLA!", 3)	
	# 3. Dengarkan sinyal saat hint selesai untuk mulai memutar Timer Game asli
	hint.hint_selesai.connect(_mulai_minigame)

func _mulai_minigame():
	print("Hint selesai, gameplay & timer minigame resmi dimulai!")
	# Jalankan timer level atau pergerakan objek di sini jika sebelumnya ditahan
	timer_global.mulai_timer(durasi_waktu)

func _buat_jalur_otomatis(tekstur: Texture2D):
	if not tekstur: return
	
	var gambar = tekstur.get_image()
	var bitmap = BitMap.new()
	# Membaca batas gambar berdasarkan transparansi (alpha) > 10%
	bitmap.create_from_image_alpha(gambar, 0.1) 
	
	var kotak_batas = Rect2(Vector2.ZERO, gambar.get_size())
	var array_poligon = bitmap.opaque_to_polygons(kotak_batas, 5.0) 
	
	if array_poligon.size() > 0:
		var kurva_baru = Curve2D.new()
		var outline_terluar = array_poligon[0] 
		
		# --- MATEMATIKA KHUSUS KEEP ASPECT CENTERED ---
		var tex_size = tekstur.get_size()
		var rect_size = kain_rect.size
		
		# 1. Cari skala terkecil (agar proporsi gambar tetap tidak gepeng)
		var skala = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		
		# 2. Hitung jarak kosong di pinggir karena gambar diposisikan di tengah
		var ukuran_visual_di_layar = tex_size * skala
		var offset_tengah = (rect_size - ukuran_visual_di_layar) / 2.0
		# -----------------------------------------------
		
		for titik in outline_terluar:
			# Kalikan setiap titik koordinat dengan skala, lalu geser posisinya ke tengah
			var titik_presisi = (titik * skala) + offset_tengah
			kurva_baru.add_point(titik_presisi)
			
		# Menutup garis pola agar ujung akhir menyambung kembali ke ujung awal
		if kurva_baru.get_point_count() > 0:
			kurva_baru.add_point(kurva_baru.get_point_position(0))
			
		jalur_pola.curve = kurva_baru
		
func _process(delta):
	# Pergerakan bolak-balik indikator (ping-pong)
	indikator.global_position.x += kecepatan_indikator * arah * delta
	
	if indikator.global_position.x >= batas_kanan:
		arah = -1
		indikator.global_position.x = batas_kanan # Koreksi agar tidak keluar jalur
	elif indikator.global_position.x <= batas_kiri:
		arah = 1
		indikator.global_position.x = batas_kiri

	# Deteksi input (Spasi di PC atau Tap di layar Android)
	if Input.is_action_just_pressed("ui_accept"):
		_cek_potongan()
	
	# Menggambar garis secara dinamis saat gunting bergerak
	if jejak_potongan.get_point_count() > 0:
		var posisi_terakhir = jejak_potongan.get_point_position(jejak_potongan.get_point_count() - 1)
		# Hanya tambah titik jika gunting sudah bergeser lebih dari 3 pixel agar rapi
		if posisi_terakhir.distance_to(pengikut_jalur.position) > 3.0: 
			jejak_potongan.add_point(pengikut_jalur.position)

func _cek_potongan():
	# Cari titik tengah gunting kecil
	var posisi_tengah_jarum = indikator.global_position.x + (indikator.size.x / 2.0)
	var batas_kiri_hijau = zona_hijau.global_position.x
	var batas_kanan_hijau = zona_hijau.global_position.x + zona_hijau.size.x
	
	if posisi_tengah_jarum >= batas_kiri_hijau and posisi_tengah_jarum <= batas_kanan_hijau:
		_sukses_memotong()
	else:
		_gagal_memotong()

func _sukses_memotong():
	progres_saat_ini += 1
	
	# Nyalakan/munculkan ikon centang di UI
	if progres_saat_ini <= target_progres:
		var centang = wadah_centang.get_child(progres_saat_ini - 1)
		centang.modulate = Color(0.0, 0.705, 0.118, 1.0) # Ubah alpha jadi terlihat
	
	# Hitung target posisi di jalur (misal target 3 potong: 0.33 -> 0.66 -> 1.0)
	var rasio_target = float(progres_saat_ini) / float(target_progres)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pengikut_jalur, "progress_ratio", rasio_target, 0.25)
	
	if progres_saat_ini >= target_progres:
		tween.finished.connect(func():
			timer_global.hentikan_timer()
			set_process(false)
			minigame_selesai.emit(true)
			print("Potongan Selesai!")
		)

func _gagal_memotong():
	# Memberikan penalti waktu atau sekadar visual gagal
	var tween_kamera = create_tween()
	for i in range(6):
		var offset_acak = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		tween_kamera.tween_property(kamera, "offset", offset_acak, 0.05)
	tween_kamera.tween_property(kamera, "offset", Vector2.ZERO, 0.05)
	
func _waktu_habis():
	set_process(false) # Langsung hentikan pergerakan jarum indikator
	timer_global.hentikan_timer()
	# Panggil efek kamera bergetar atau animasi robek
	_gagal_memotong() 
	minigame_selesai.emit(false)
	print("Waktu habis! Gagal memotong sesuai pola.")
