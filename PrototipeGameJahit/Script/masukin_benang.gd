extends Control

signal minigame_selesai(sukses: bool)

@onready var bar_ketenangan = $BarKetenangan
@onready var timer_game = $Timer
@onready var bar_waktu = $ProgressBar # Opsional, jika kamu pakai bar waktu visual
@onready var wadah_jarum = $WadahJarum # Wadah yang menampung gambar jarum & benang

@export var durasi_waktu: float = 10.0
@export var ketenangan_berkurang_per_detik: float = 25.0 # Kecepatan bar turun
@export var tambah_ketenangan_per_tap: float = 10 # Jumlah bar naik tiap kali di-tap

var game_aktif: bool = false
var posisi_awal_jarum: Vector2

func _ready():
	# Simpan posisi awal wadah agar getarannya tidak membuatnya bergeser jauh
	posisi_awal_jarum = wadah_jarum.position
	
	bar_ketenangan.value = 0
	bar_ketenangan.max_value = 150
	
	timer_game.timeout.connect(_kalah)
	
	# Sementara langsung dimulai. Nanti bisa dipanggil lewat sinyal HintOverlay
	_mulai_minigame()

func _mulai_minigame():
	timer_game.start(durasi_waktu)
	bar_waktu.max_value = durasi_waktu # Jika pakai bar waktu
	game_aktif = true

func _process(delta):
	if not game_aktif: return
	
	# Update bar waktu (jika ada)
	if bar_waktu:
		bar_waktu.value = timer_game.time_left
		
	# Mekanik Bar Ketenangan (Selalu merosot turun seiring waktu)
	if bar_ketenangan.value > 0:
		bar_ketenangan.value -= ketenangan_berkurang_per_detik * delta
		
	# Mekanik Visual: Jarum bergetar sesuai tingkat stres
	_aplikasikan_getaran()

func _aplikasikan_getaran():
	# Level stres: 1.0 (sangat gemetar saat bar kosong) sampai 0.0 (tenang saat bar penuh)
	var level_stres = 1.0 - (bar_ketenangan.value / bar_ketenangan.max_value)
	var intensitas_maksimal = 20.0 # Semakin besar, semakin liar getarannya
	
	# Jika stres masih ada, acak posisinya. Jika sudah 0 (tenang), kembalikan ke tengah.
	if level_stres > 0.05:
		var getaran_acak_x = randf_range(-1.0, 1.0) * intensitas_maksimal * level_stres
		var getaran_acak_y = randf_range(-1.0, 1.0) * intensitas_maksimal * level_stres
		wadah_jarum.position = posisi_awal_jarum + Vector2(getaran_acak_x, getaran_acak_y)
	else:
		wadah_jarum.position = posisi_awal_jarum

# Mendeteksi klik mouse, ketukan layar, atau tombol spasi
func _input(event):
	if not game_aktif: return
	
	# Deteksi tombol spasi/enter ATAU klik kiri mouse ATAU tap layar HP
	var ditekan = event.is_action_pressed("ui_accept") or \
				  (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or \
				  (event is InputEventScreenTouch and event.pressed)
	
	if ditekan:
		get_viewport().set_input_as_handled()
		bar_ketenangan.value += tambah_ketenangan_per_tap
		
		# Cek Kondisi Menang
		if bar_ketenangan.value >= bar_ketenangan.max_value:
			_menang()

func _menang():
	game_aktif = false
	timer_game.stop()
	wadah_jarum.position = posisi_awal_jarum # Kembalikan jarum ke posisi diam
	
	print("Ketenangan penuh! Putar animasi benang masuk.")
	# TODO: Panggil fungsi/Tween animasi sukses di sini nanti
	
	# Beri sedikit jeda sebelum melapor ke Manager agar pemain bisa melihat animasinya
	await get_tree().create_timer(1.0).timeout 
	minigame_selesai.emit(true)

func _kalah():
	game_aktif = false
	wadah_jarum.position = posisi_awal_jarum
	
	print("Waktu Habis! Putar animasi MC pusing.")
	# TODO: Panggil fungsi/Tween animasi gagal di sini nanti
	
	await get_tree().create_timer(1.0).timeout
	minigame_selesai.emit(false)
