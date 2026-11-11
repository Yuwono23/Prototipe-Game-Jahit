extends CanvasLayer # Atau Control, sesuaikan dengan tipe root node HintOverlay

signal hint_selesai

# ==========================================
# VARIABEL PENGATURAN (EDIT DI INSPECTOR)
# ==========================================
@export_category("Pengaturan Mode")
@export var is_tutorial: bool = false
@export var judul_dialog_tutorial: String = "" # Judul naskah di .dialogue (misal: "hint_potong")

@export_category("Data Hint")
@export_multiline var teks_petunjuk: String = "INI PERINTAH"
@export var tekstur_gambar1: Texture2D
@export var tekstur_gambar2: Texture2D
@export var durasi_hint: float = 3.0 # Durasi hint untuk level biasa

# ==========================================
# REFERENSI NODE
# ==========================================
@onready var background_blur = $BackgroundBlur
@onready var wadah_konten = $WadahKonten
@onready var teks_instruksi = $WadahKonten/TeksInstruksi
@onready var gambar1 = $WadahKonten/Background/WadahGambar/Gambar1
@onready var gambar2 = $WadahKonten/Background/WadahGambar/Gambar2

# Referensi ke file naskah dialog utama kita
const FILE_CERITA = preload("res://Dialogue/cerita_tutorial.dialogue")

func _ready():
	# Sembunyikan UI bawaan saat scene dimuat
	background_blur.hide()
	wadah_konten.hide()

# Fungsi utama yang dipanggil oleh minigame
func mulai_tampilkan_hint():
	if is_tutorial:
		_tampilkan_hint_tutorial()
	else:
		_tampilkan_hint_biasa()

# --- MODE 1: HINT LEVEL BIASA ---
func _tampilkan_hint_biasa():
	# Set data ke UI
	teks_instruksi.text = teks_petunjuk
	
	if tekstur_gambar1:
		gambar1.texture = tekstur_gambar1
	if tekstur_gambar2:
		gambar2.texture = tekstur_gambar2
		
	# Munculkan UI
	background_blur.show()
	wadah_konten.show()
	
	# Tunggu sesuai durasi
	await get_tree().create_timer(durasi_hint).timeout
	
	# Sembunyikan UI dan kirim sinyal lanjut
	background_blur.hide()
	wadah_konten.hide()
	hint_selesai.emit()

# --- MODE 2: HINT LEVEL TUTORIAL ---
func _tampilkan_hint_tutorial():
	GlobalData.hint_gambar_kiri = tekstur_gambar1
	GlobalData.hint_gambar_kanan = tekstur_gambar2
	
	# Panggil Scene DialogueSystem milikmu secara spesifik
	var ui_dialog = preload("res://Scene/DialogueSystem.tscn")
	DialogueManager.show_dialogue_balloon_scene(ui_dialog, FILE_CERITA, judul_dialog_tutorial)
	
	await DialogueManager.dialogue_ended 
	hint_selesai.emit()
