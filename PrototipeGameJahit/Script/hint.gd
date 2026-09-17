extends CanvasLayer

signal hint_selesai 

@export var gambar_ilustrasi: Array[Texture2D] = []

@onready var wadah_konten = $WadahKonten
@onready var wadah_gambar = $WadahKonten/Background/WadahGambar
@onready var teks_instruksi = $WadahKonten/TeksInstruksi
@onready var teks_countdown = $WadahKonten/TeksCountdown
@onready var timer_countdown = $TimerCountdown
@onready var background = $WadahKonten/Background

@onready var gambar_1 = $WadahKonten/Background/WadahGambar/Gambar1
@onready var gambar_2 = $WadahKonten/Background/WadahGambar/Gambar2

var hitung_mundur: int = 3
var fase_hint: bool = true # Menandai apakah kita sedang di tahap melihat hint

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	timer_countdown.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Pastikan teks hitung mundur tersembunyi di awal
	teks_countdown.visible = false

func tampilkan_hint(pesan_instruksi: String, durasi_hint: float = 2.0, ilustrasi_kustom: Array[Texture2D] = []):
	teks_instruksi.text = pesan_instruksi
	hitung_mundur = 3 # Hitung mundur akan selalu 3 detik
	fase_hint = true
	
	var daftar_gambar = ilustrasi_kustom if ilustrasi_kustom.size() > 0 else gambar_ilustrasi
	_atur_tampilan_gambar(daftar_gambar)
	
	# Tampilkan hint, sembunyikan countdown
	wadah_gambar.visible = true
	teks_instruksi.visible = true
	teks_countdown.visible = false
	
	get_tree().paused = true
	
	wadah_konten.pivot_offset = wadah_konten.size / 2.0
	wadah_konten.scale = Vector2.ZERO
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(wadah_konten, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	if not timer_countdown.timeout.is_connected(_pada_timer_tick):
		timer_countdown.timeout.connect(_pada_timer_tick)
		
	# Mulai timer dengan durasi hint (misal 2 detik) sebelum berganti ke angka 3
	timer_countdown.start(durasi_hint)

func _atur_tampilan_gambar(daftar_gambar: Array[Texture2D]):
	if daftar_gambar.size() == 0:
		gambar_1.visible = false
		gambar_2.visible = false
	elif daftar_gambar.size() == 1:
		gambar_1.texture = daftar_gambar[0]
		gambar_1.visible = true
		gambar_2.visible = false
	else:
		gambar_1.texture = daftar_gambar[0]
		gambar_1.visible = true
		gambar_2.texture = daftar_gambar[1]
		gambar_2.visible = true

func _pada_timer_tick():
	if fase_hint:
		# TRANSISI: Fase Hint selesai, mulai Fase Hitung Mundur
		fase_hint = false
		
		# Sembunyikan gambar dan teks instruksi
		background.visible = false
		wadah_gambar.visible = false
		teks_instruksi.visible = false
		
		# Munculkan angka 3
		teks_countdown.visible = true
		teks_countdown.text = str(hitung_mundur)
		_animasi_teks_countdown()
		
		# Ubah kecepatan timer menjadi 1 detik untuk hitung mundur
		timer_countdown.start(1.0)
	else:
		# FASE HITUNG MUNDUR (3.. 2.. 1.. MULAI)
		hitung_mundur -= 1
		
		if hitung_mundur > 0:
			teks_countdown.text = str(hitung_mundur)
			_animasi_teks_countdown()
		elif hitung_mundur == 0:
			teks_countdown.text = "MULAI!"
			_animasi_teks_countdown()
		else:
			# Hitungan habis, bersihkan overlay dan mulai game
			timer_countdown.stop()
			get_tree().paused = false
			hint_selesai.emit()
			queue_free()

# Fungsi pembantu agar kode animasi tidak diulang-ulang
func _animasi_teks_countdown():
	teks_countdown.pivot_offset = teks_countdown.size / 2.0
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(teks_countdown, "scale", Vector2(1.4, 1.4), 0.1)
	tween.tween_property(teks_countdown, "scale", Vector2.ONE, 0.1)
