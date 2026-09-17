extends Node

@export var urutan_minigame: Array[PackedScene] = []

@onready var wadah_minigame = $WadahMinigame
@onready var layar_hitam = $CanvasLayerTransisi/LayarHitam

var indeks_level_saat_ini: int = 0

func _ready():
	# Pastikan layar mulai dari keadaan transparan penuh di awal level
	# agar tidak menutupi pop-up Hint minigame pertama
	layar_hitam.modulate.a = 0.0
	muat_minigame_selanjutnya()
	
func muat_minigame_selanjutnya():
	if indeks_level_saat_ini < urutan_minigame.size():
		var minigame_baru = urutan_minigame[indeks_level_saat_ini].instantiate()
		wadah_minigame.add_child(minigame_baru)
		
		minigame_baru.minigame_selesai.connect(_pada_minigame_selesai)
		
		indeks_level_saat_ini += 1
		
		# Animasi Fade In (Gelap perlahan memudar menjadi transparan)
		var tween = create_tween()
		tween.tween_property(layar_hitam, "modulate:a", 0.0, 0.4)
	else:
		_level_tutorial_tamat()

func _pada_minigame_selesai(sukses: bool):
	if sukses:
		GlobalData.tambah_poin(1)
		print("Berhasil! Poin ditambahkan. Total Poin: ", GlobalData.total_poin)
	else:
		print("Gagal! Lanjut ke tahap berikutnya tanpa poin.")
	
	# Animasi Fade Out (Transparan perlahan berubah menjadi Gelap)
	var tween = create_tween()
	tween.tween_property(layar_hitam, "modulate:a", 1.0, 0.4)
	
	# Tunggu sampai layar benar-benar gelap
	await tween.finished
	
	# Bersihkan minigame lama yang tersembunyi di balik layar gelap
	for anak in wadah_minigame.get_children():
		anak.queue_free()
		
	# Berikan jeda sejenak saat gelap gulita agar pemain bisa bernapas
	await get_tree().create_timer(0.3).timeout
	
	# Panggil minigame selanjutnya
	muat_minigame_selanjutnya()

func _level_tutorial_tamat():
	print("TUTORIAL SELESAI! Total Poin Terkumpul: ", GlobalData.total_poin)
	# Opsional: Jika menang tutorial, buka kunci level di GlobalData
