extends Control

@onready var indikator = $UI_SkillCheck/IndikatorJarum
@onready var zona_hijau = $UI_SkillCheck/BackgroundBar/ZonaHijau
@onready var bg_bar = $UI_SkillCheck/BackgroundBar
@onready var gunting_besar = $VisualPotong/Kain/LintasanPola/PengikutJalur/GuntingBesar
@onready var kamera = $Kamera
@onready var wadah_centang = $UI_SkillCheck/WadahCentang
@onready var jalur_pola = $VisualPotong/Kain/LintasanPola
@onready var pengikut_jalur = $VisualPotong/Kain/LintasanPola/PengikutJalur
@onready var jejak_potongan = $VisualPotong/Kain/LintasanPola/JejakPotongan
@onready var kain_rect = $VisualPotong/Kain 
@onready var timer_global = $TimerGlobal
@onready var latar_kain = $BackgroundKain

@onready var node_hint = $HintOverlay

@export var durasi_waktu: float = 10.0
signal minigame_selesai(sukses: bool)

var kecepatan_indikator = 500.0
var arah = 1
var batas_kiri = 0.0
var batas_kanan = 0.0
var target_progres = 3
var progres_saat_ini = 0
var game_aktif = false

func _ready():
	# [BARU] Paksa node lintasan dan jejak ke titik 0 agar sejajar dengan kain
	jalur_pola.position = Vector2.ZERO
	jejak_potongan.position = Vector2.ZERO
	if GlobalData.tekstur_kain_terpilih != null:
		latar_kain.texture = GlobalData.tekstur_kain_terpilih
	_buat_jalur_otomatis(kain_rect.texture)
	
	batas_kiri = bg_bar.global_position.x
	batas_kanan = bg_bar.global_position.x + bg_bar.size.x - indikator.size.x
	
	jejak_potongan.clear_points()
	jejak_potongan.add_point(pengikut_jalur.position)
	
	# [BARU] Pastikan gunting dalam posisi diam/terbuka di awal
	gunting_besar.play("diam")
	
	node_hint.hint_selesai.connect(_mulai_minigame)
	node_hint.mulai_tampilkan_hint()

func _mulai_minigame():
	print("Hint selesai, gameplay & timer minigame resmi dimulai!")
	game_aktif = true 
	timer_global.mulai_timer(durasi_waktu)

func _buat_jalur_otomatis(tekstur: Texture2D):
	if not tekstur: return
	
	var gambar = tekstur.get_image()
	var bitmap = BitMap.new()
	bitmap.create_from_image_alpha(gambar, 0.1) 
	
	var kotak_batas = Rect2(Vector2.ZERO, gambar.get_size())
	var array_poligon = bitmap.opaque_to_polygons(kotak_batas, 0.1)
	
	if array_poligon.size() > 0:
		var kurva_baru = Curve2D.new()
		var outline_terluar = array_poligon[0] 
		
		var tex_size = tekstur.get_size()
		var rect_size = kain_rect.size
		
		var skala = min(rect_size.x / tex_size.x, rect_size.y / tex_size.y)
		var ukuran_visual_di_layar = tex_size * skala
		var offset_tengah = (rect_size - ukuran_visual_di_layar) / 2.0
		
		for titik in outline_terluar:
			var titik_presisi = (titik * skala) + offset_tengah
			kurva_baru.add_point(titik_presisi)
			
		if kurva_baru.get_point_count() > 0:
			kurva_baru.add_point(kurva_baru.get_point_position(0))
			
		jalur_pola.curve = kurva_baru
		
func _process(delta):
	if not game_aktif: return
	
	indikator.global_position.x += kecepatan_indikator * arah * delta
	
	if indikator.global_position.x >= batas_kanan:
		arah = -1
		indikator.global_position.x = batas_kanan 
	elif indikator.global_position.x <= batas_kiri:
		arah = 1
		indikator.global_position.x = batas_kiri

	if Input.is_action_just_pressed("ui_accept"):
		_cek_potongan()
	
	if jejak_potongan.get_point_count() > 0:
		var posisi_terakhir = jejak_potongan.get_point_position(jejak_potongan.get_point_count() - 1)
		if posisi_terakhir.distance_to(pengikut_jalur.position) > 3.0: 
			jejak_potongan.add_point(pengikut_jalur.position)

func _cek_potongan():
	var posisi_tengah_jarum = indikator.global_position.x + (indikator.size.x / 2.0)
	var batas_kiri_hijau = zona_hijau.global_position.x
	var batas_kanan_hijau = zona_hijau.global_position.x + zona_hijau.size.x
	
	if posisi_tengah_jarum >= batas_kiri_hijau and posisi_tengah_jarum <= batas_kanan_hijau:
		_sukses_memotong()
	else:
		_gagal_memotong()

func _sukses_memotong():
	progres_saat_ini += 1
	
	# [BARU] Mulai animasi buka-tutup gunting saat tombol ditekan dengan benar
	gunting_besar.play("potong")
	
	if progres_saat_ini <= target_progres:
		var centang = wadah_centang.get_child(progres_saat_ini - 1)
		centang.modulate = Color(0.0, 0.705, 0.118, 1.0) 
	
	var rasio_target = float(progres_saat_ini) / float(target_progres)
	
	var tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(pengikut_jalur, "progress_ratio", rasio_target, 0.25)
	
	if progres_saat_ini >= target_progres:
		tween.finished.connect(func():
			gunting_besar.play("diam") # [BARU] Hentikan gunting di akhir level
			timer_global.hentikan_timer()
			set_process(false)
			minigame_selesai.emit(true)
			print("Potongan Selesai!")
		)
	else:
		# [BARU] Hentikan gunting dan kembalikan ke posisi terbuka setelah pergerakan titik ini selesai
		tween.finished.connect(func():
			gunting_besar.play("diam")
		)

func _gagal_memotong():
	var tween_kamera = create_tween()
	for i in range(6):
		var offset_acak = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		tween_kamera.tween_property(kamera, "offset", offset_acak, 0.05)
	tween_kamera.tween_property(kamera, "offset", Vector2.ZERO, 0.05)
	
func _waktu_habis():
	set_process(false) 
	timer_global.hentikan_timer()
	_gagal_memotong() 
	minigame_selesai.emit(false)
	print("Waktu habis! Gagal memotong sesuai pola.")
