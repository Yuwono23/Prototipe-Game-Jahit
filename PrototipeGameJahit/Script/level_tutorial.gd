extends Node

@export var urutan_minigame: Array[PackedScene] = []

@onready var wadah_minigame = $WadahMinigame
@onready var layar_hitam = $CanvasLayerTransisi/LayarHitam

const FILE_CERITA = preload("res://Dialogue/cerita_tutorial.dialogue") # Pastikan path sesuai
const UI_DIALOG = preload("res://Scene/DialogueSystem.tscn")

var daftar_nama_minigame = ["pilih_kain", "potong_kain", "jahit_kain"]
var skor_kemenangan = 0 # [BARU] Variabel untuk melacak jumlah keberhasilan

func _ready():
	layar_hitam.modulate.a = 1.0
	layar_hitam.process_mode = Node.PROCESS_MODE_ALWAYS
	_jalankan_skenario_sutradara()

func _jalankan_skenario_sutradara():
	skor_kemenangan = 0 # Reset skor di awal
	
	# 1. BUKA LAYAR & INTRO
	var tween_buka = layar_hitam.create_tween()
	tween_buka.tween_property(layar_hitam, "modulate:a", 0.0, 0.5)
	await tween_buka.finished
	
	DialogueManager.show_dialogue_balloon_scene(UI_DIALOG.instantiate(), FILE_CERITA, "intro")
	await DialogueManager.dialogue_ended
	
	# [BARU] FADE OUT SETELAH INTRO (Sebelum Minigame 1)
	var tween_tutup_intro = layar_hitam.create_tween()
	tween_tutup_intro.tween_property(layar_hitam, "modulate:a", 1.0, 0.4)
	await tween_tutup_intro.finished
	
	# Buka layar perlahan untuk minigame pertama
	var tween_buka_minigame1 = layar_hitam.create_tween()
	tween_buka_minigame1.tween_property(layar_hitam, "modulate:a", 0.0, 0.4)
	await tween_buka_minigame1.finished
	
	# 2. LOOPING SEMUA MINIGAME
	for i in range(urutan_minigame.size()):
		var minigame_baru = urutan_minigame[i].instantiate()
		var node_hint = minigame_baru.get_node_or_null("HintOverlay")
		var nama_fase = daftar_nama_minigame[i] if i < daftar_nama_minigame.size() else "umum"
		
		if node_hint:
			node_hint.is_tutorial = true
			node_hint.judul_dialog_tutorial = "hint_" + nama_fase
			
		wadah_minigame.add_child(minigame_baru)
		
		var sukses = await minigame_baru.minigame_selesai 
		await get_tree().create_timer(1.0).timeout
		
		# [BARU] Hitung Skor Keberhasilan
		if sukses:
			skor_kemenangan += 1
		
		if sukses:
			DialogueManager.show_dialogue_balloon_scene(UI_DIALOG.instantiate(), FILE_CERITA, "menang_" + nama_fase)
		else:
			DialogueManager.show_dialogue_balloon_scene(UI_DIALOG.instantiate(), FILE_CERITA, "kalah_" + nama_fase)
			
		await DialogueManager.dialogue_ended
		
		var tween_tutup = layar_hitam.create_tween()
		tween_tutup.tween_property(layar_hitam, "modulate:a", 1.0, 0.4)
		await tween_tutup.finished
		
		minigame_baru.queue_free()
		await get_tree().create_timer(0.2).timeout
		
		# Buka layar lagi (hanya jika masih ada minigame, atau untuk dialog akhir)
		var tween_buka_lagi = layar_hitam.create_tween()
		tween_buka_lagi.tween_property(layar_hitam, "modulate:a", 0.0, 0.4)
		await tween_buka_lagi.finished

	# 3. [BARU] EVALUASI AKHIR (POST DIALOG)
	# Jika berhasil di mayoritas minigame (misal: 2 atau 3 dari 3)
	if skor_kemenangan >= 2:
		DialogueManager.show_dialogue_balloon_scene(UI_DIALOG.instantiate(), FILE_CERITA, "evaluasi_lulus")
	else:
		DialogueManager.show_dialogue_balloon_scene(UI_DIALOG.instantiate(), FILE_CERITA, "evaluasi_gagal")
		
	await DialogueManager.dialogue_ended
	
	# Transisi penutup level
	var tween_tutup_final = layar_hitam.create_tween()
	tween_tutup_final.tween_property(layar_hitam, "modulate:a", 1.0, 1.0)
	await tween_tutup_final.finished
	
	print("Tutorial Selesai. Pindah ke Scene Berikutnya (Misal: Main Menu) di sini!")
