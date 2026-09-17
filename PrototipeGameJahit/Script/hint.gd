extends CanvasLayer

signal hint_selesai 

@export var gambar_ilustrasi: Array[Texture2D] = []

@onready var wadah_konten = $WadahKonten
@onready var wadah_gambar = $WadahKonten/Background/WadahGambar
@onready var teks_instruksi = $WadahKonten/TeksInstruksi

@onready var gambar_1 = $WadahKonten/Background/WadahGambar/Gambar1
@onready var gambar_2 = $WadahKonten/Background/WadahGambar/Gambar2

func _ready():
	# Pastikan scene ini tetap berjalan meskipun game di-pause
	process_mode = Node.PROCESS_MODE_ALWAYS

func tampilkan_hint(pesan_instruksi: String, durasi_hint: float = 1.5, ilustrasi_kustom: Array[Texture2D] = []):
	teks_instruksi.text = pesan_instruksi
	
	var daftar_gambar = ilustrasi_kustom if ilustrasi_kustom.size() > 0 else gambar_ilustrasi
	_atur_tampilan_gambar(daftar_gambar)
	
	wadah_gambar.visible = true
	teks_instruksi.visible = true
	
	# Hentikan waktu game di latar belakang
	get_tree().paused = true
	
	# Animasi pop-up mekar dari tengah
	wadah_konten.pivot_offset = wadah_konten.size / 2.0
	wadah_konten.scale = Vector2.ZERO
	
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(wadah_konten, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# --- CARA BARU YANG LEBIH BERSIH ---
	# Menunggu selama durasi_hint secara otomatis tanpa perlu Node Timer
	await get_tree().create_timer(durasi_hint).timeout
	
	# Setelah menunggu, langsung hapus hint dan mulai game!
	get_tree().paused = false
	hint_selesai.emit()
	queue_free()

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
