extends Control

signal minigame_selesai(sukses: bool)

@export var scene_sobekan: PackedScene # Masukkan Sobekan.tscn di Inspector
@export var durasi_waktu: float = 15.0
@export var target_sobekan: int = 4 # Jumlah sobekan yang harus dicari

@onready var wadah_titik = $Baju/WadahTitik
@onready var timer_global = $TimerGlobal

var jumlah_ditemukan: int = 0
var game_aktif: bool = false

func _ready():
	timer_global.waktu_habis.connect(_kalah)
	_sebar_sobekan()
	_mulai_minigame()

func _sebar_sobekan():
	var semua_titik = wadah_titik.get_children()
	
	# Acak urutan titik di dalam array
	semua_titik.shuffle() 
	
	# Pastikan target tidak melebihi jumlah marker yang kamu pasang di editor
	target_sobekan = min(target_sobekan, semua_titik.size())
	
	# Munculkan sobekan hanya di beberapa titik terpilih
	for i in range(target_sobekan):
		var titik_lokasi = semua_titik[i]
		var sobekan_baru = scene_sobekan.instantiate()
		
		titik_lokasi.add_child(sobekan_baru)
		
		# Menggeser TextureButton agar tepat berada di tengah Marker2D
		sobekan_baru.position = -sobekan_baru.size / 2.0
		
		# Dengarkan saat sobekan ini ditekan pemain
		sobekan_baru.sobekan_ditekan.connect(_cek_progres)

func _mulai_minigame():
	game_aktif = true
	timer_global.mulai_timer(durasi_waktu)

func _cek_progres():
	if not game_aktif: return
	
	jumlah_ditemukan += 1
	
	if jumlah_ditemukan >= target_sobekan:
		_menang()

func _menang():
	game_aktif = false
	timer_global.hentikan_timer()
	print("Semua sobekan berhasil ditandai!")
	minigame_selesai.emit(true)

func _kalah():
	game_aktif = false
	print("Waktu habis! Masih ada sobekan yang terlewat.")
	minigame_selesai.emit(false)
