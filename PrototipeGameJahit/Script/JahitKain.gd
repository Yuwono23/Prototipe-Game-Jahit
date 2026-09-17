extends Control

const HINT_OVERLAY_SCENE = preload("res://Scene/Hint.tscn") # Sesuaikan path file-mu
@onready var jalur_biru = $JalurBiru
@onready var bar_hijau = $JalurBiru/BarHijau
@onready var jarum = $JalurBiru/Jarum
@onready var bar_progres = $BarProgres
@onready var timer_game = $Timer
@onready var bar_waktu = $ProgressBar
# Pengaturan Fisika yang bisa diubah langsung di Inspector
@export var gravitasi = 1200.0
@export var daya_angkat = -2500.0
@export var kecepatan_isi = 25.0
@export var kecepatan_turun = 15.0
@export var durasi_waktu: float = 10.0
#Pengaturan Kecepatan Jarum AI
@export var kecepatan_jarum = 150.0 
var arah_jarum = 1 # 1 untuk bergerak ke bawah, -1 untuk ke atas
signal minigame_selesai(sukses: bool)

var kecepatan_bar = 0.0
var progres_jahit = 30.0 # Diberi modal awal 30% agar pemain tidak langsung kalah di detik pertama
var target_y_jarum = 0.0
var waktu_pindah_jarum = 0.0
var game_aktif = true
var tween_jarum: Tween #Simpan referensi Tween

func _ready():
	timer_game.timeout.connect(_waktu_habis)
	bar_progres.value = progres_jahit
	bar_waktu.value = 100.0
	_mulai_animasi_jarum() #Panggil fungsi animasi
	
	# 1. Spawn Hint Overlay
	var hint = HINT_OVERLAY_SCENE.instantiate()
	add_child(hint)
	# 2. Tentukan Teks Instruksi untuk minigame ini (misal: "JAHIT!")
	hint.tampilkan_hint("JAHIT PAKAIANMU!", 3)	
	# 3. Dengarkan sinyal saat hint selesai untuk mulai memutar Timer Game asli
	hint.hint_selesai.connect(_mulai_minigame)

func _mulai_minigame():
	print("Hint selesai, gameplay & timer minigame resmi dimulai!")
	# Jalankan timer level atau pergerakan objek di sini jika sebelumnya ditahan
	timer_game.start(durasi_waktu)

func _mulai_animasi_jarum():
	var batas_bawah = jalur_biru.size.y - jarum.size.y
	
	# Menghitung berapa lama waktu yang dibutuhkan untuk dari ujung ke ujung
	# Rumus: Waktu = Jarak / Kecepatan
	var durasi = batas_bawah / kecepatan_jarum
	# Buat Tween yang mengulang (loop) tanpa batas
	tween_jarum = create_tween().set_loops()
	# Pastikan jarum mulai dari atas
	jarum.position.y = 0.0
	# 1. Animasi bergerak ke bawah dengan kecepatan stabil (Linear)
	tween_jarum.tween_property(jarum, "position:y", batas_bawah, durasi).set_trans(Tween.TRANS_LINEAR)
	# 2. Animasi bergerak kembali ke atas dengan kecepatan stabil
	tween_jarum.tween_property(jarum, "position:y", 0.0, durasi).set_trans(Tween.TRANS_LINEAR)
	
func _process(delta):
	if not game_aktif: return
	if not timer_game.is_stopped():
		bar_waktu.value = (timer_game.time_left / timer_game.wait_time) * 100.0
	# 1. Fisika Bar Hijau (Input Pemain)
	# Tekan Spasi, Klik Kiri, atau Sentuh Layar
	if Input.is_action_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		kecepatan_bar += daya_angkat * delta
	else:
		kecepatan_bar += gravitasi * delta

	bar_hijau.position.y += kecepatan_bar * delta

	# Batasi pergerakan bar hijau agar tidak tembus ke luar jalur biru
	var batas_bawah_bar = jalur_biru.size.y - bar_hijau.size.y
	if bar_hijau.position.y < 0:
		bar_hijau.position.y = 0
		kecepatan_bar = 0 # Matikan momentum saat menabrak atap
	elif bar_hijau.position.y > batas_bawah_bar:
		bar_hijau.position.y = batas_bawah_bar
		kecepatan_bar = 0 # Matikan momentum saat menabrak dasar
		
	# 2. Pergerakan AI Jarum
	waktu_pindah_jarum -= delta
	if waktu_pindah_jarum <= 0:
		_acak_posisi_jarum()

	# Bergerak mulus mengejar target posisi Y menggunakan lerp
	jarum.position.y = lerp(jarum.position.y, target_y_jarum, 2.0 * delta)

	# 3. Deteksi "Skill Check"
	_cek_progres(delta)

func _cek_progres(delta):
	var pusat_jarum = jarum.position.y + (jarum.size.y / 2.0)
	var atas_bar = bar_hijau.position.y
	var bawah_bar = bar_hijau.position.y + bar_hijau.size.y

	# Jika jarum ada di dalam area bar hijau
	if pusat_jarum >= atas_bar and pusat_jarum <= bawah_bar:
		progres_jahit += kecepatan_isi * delta
		bar_hijau.color = Color(0, 1, 0) # Berubah hijau terang sebagai visual feedback
	else:
		progres_jahit -= kecepatan_turun * delta
		bar_hijau.color = Color(0.5, 0.8, 0.5) # Hijau pudar jika meleset

	# Pastikan nilai tidak bocor di bawah 0 atau di atas 100
	progres_jahit = clamp(progres_jahit, 0, 100)
	bar_progres.value = progres_jahit

	# 4. Kondisi Menang/Kalah
	if progres_jahit >= 100:
		_menang()
	elif progres_jahit <= 0:
		_kalah()

func _acak_posisi_jarum():
	# Mencari titik acak baru untuk didatangi jarum
	var batas_bawah_jarum = jalur_biru.size.y - jarum.size.y
	target_y_jarum = randf_range(0.0, batas_bawah_jarum)
	
	# Jarum akan diam di titik tersebut selama 0.5 - 1.5 detik sebelum pindah lagi
	waktu_pindah_jarum = randf_range(0.5, 1.5) 

func _menang():
	game_aktif = false
	timer_game.stop()
	if tween_jarum: tween_jarum.kill() # Hentikan jarum saat menang
	minigame_selesai.emit(true)
	print("Menang! Jahitan selesai dengan rapi.")

func _kalah():
	game_aktif = false
	timer_game.stop()
	if tween_jarum: tween_jarum.kill() # Hentikan jarum saat kalah
	minigame_selesai.emit(false)
	print("Kalah! Progres habis atau waktu habis.")

func _waktu_habis():
	if game_aktif:
		bar_waktu.value = 0 # Pastikan bar benar-benar kosong saat waktu habis
		_kalah()
