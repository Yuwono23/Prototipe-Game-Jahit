extends Control

signal minigame_selesai(sukses: bool)

@export var scene_kancing: PackedScene # Masukkan file KancingJatuh.tscn ke sini via Inspector
@export var durasi_waktu: float = 20.0
@export var target_jumlah: int = 10
@export var penalti_salah: float = 3.0 # Waktu berkurang 3 detik jika salah ambil

@onready var timer_global = $TimerGlobal
@onready var timer_spawn = $TimerSpawn
@onready var keranjang = $KeranjangPemain
@onready var ikon_target = $UI_Hint/TextureRect
@onready var label_target = $UI_Hint/Label

# Daftar warna yang mungkin muncul (Merah, Ungu, Biru, Hijau, Kuning)
var daftar_warna: Array[Color] = [Color.RED, Color.PURPLE, Color.BLUE, Color.GREEN, Color.YELLOW]
var id_target: int = 0
var jumlah_terkumpul: int = 0
var game_aktif: bool = false

func _ready():
	timer_global.waktu_habis.connect(_kalah)
	timer_spawn.timeout.connect(_spawn_kancing)
	
	# Hubungkan area masuk untuk mendeteksi tangkapan keranjang
	keranjang.area_entered.connect(_pada_kancing_tertangkap)
	
	_siapkan_target()
	_mulai_minigame()

func _siapkan_target():
	# Pilih warna acak untuk dijadikan target
	id_target = randi() % daftar_warna.size()
	ikon_target.modulate = daftar_warna[id_target]
	_update_label_target()

func _mulai_minigame():
	game_aktif = true
	timer_global.mulai_timer(durasi_waktu)
	timer_spawn.start(0.8) # Spawn kancing tiap 0.8 detik

func _process(_delta):
	if not game_aktif: return
	
	# Membuat keranjang mengikuti posisi X dari mouse / sentuhan jari
	var batas_kiri = 50
	var batas_kanan = get_viewport_rect().size.x - 50
	var target_x = get_global_mouse_position().x
	
	# Batasi agar keranjang tidak tembus batas layar
	keranjang.global_position.x = clamp(target_x, batas_kiri, batas_kanan)

func _spawn_kancing():
	var kancing_baru = scene_kancing.instantiate()
	add_child(kancing_baru)
	
	# Acak id warnanya. Buat agar warna target lebih sering muncul (misal 40% kemungkinan)
	var id_acak = id_target if randf() < 0.4 else randi() % daftar_warna.size()
	
	var x_acak = randf_range(100, get_viewport_rect().size.x - 100)
	kancing_baru.global_position = Vector2(x_acak, -50)
	
	var kecepatan_acak = randf_range(200.0, 400.0)
	kancing_baru.setup(daftar_warna[id_acak], id_acak, kecepatan_acak)

func _pada_kancing_tertangkap(area_yang_masuk: Area2D):
	if not game_aktif: return
	
	# Cek apakah yang masuk benar-benar objek kancing
	if area_yang_masuk.has_method("setup"):
		if area_yang_masuk.id_warna == id_target:
			# BENAR!
			jumlah_terkumpul += 1
			_update_label_target()
			
			if jumlah_terkumpul >= target_jumlah:
				_menang()
		else:
			# SALAH!
			timer_global.kurangi_waktu(penalti_salah)
			print("Salah ambil! Waktu dikurangi ", penalti_salah, " detik!")
			# TODO: Tambahkan efek layar bergetar atau suara error di sini
			
		# Hapus kancing setelah ditangkap
		area_yang_masuk.queue_free()

func _update_label_target():
	var sisa = target_jumlah - jumlah_terkumpul
	label_target.text = "x " + str(sisa)

func _menang():
	game_aktif = false
	timer_global.hentikan_timer()
	timer_spawn.stop()
	print("Menang! Semua kancing terkumpul.")
	minigame_selesai.emit(true)

func _kalah():
	game_aktif = false
	timer_spawn.stop()
	print("Waktu habis! Kancing kurang.")
	minigame_selesai.emit(false)
