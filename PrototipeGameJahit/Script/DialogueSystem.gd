extends CanvasLayer

# --- REFERENSI NODE LAMA ---
@onready var label_nama = $PanelDialog/NamaKarakter
@onready var label_teks = $PanelDialog/TeksDialog 
@onready var portret_kiri = $PortretKiri
@onready var portret_kanan = $PortretKanan
@onready var portret_tengah = $PortretTengah

# --- REFERENSI NODE HINT ---
@onready var node_hint = $Hint
@onready var hint_gambar1 = $Hint/WadahKonten/Background/WadahGambar/Gambar1
@onready var hint_gambar2 = $Hint/WadahKonten/Background/WadahGambar/Gambar2

# --- REFERENSI BLUR & BACKGROUND ---
@onready var efek_blur = $EfekBlur
@onready var bg_gambar = $EfekBlur/BackgroundGambar

const PATH_KARAKTER = "res://Asset/Placeholder/"
const PATH_BG = "res://Asset/Background/" 

var resource_dialog: DialogueResource
var is_waiting_for_input: bool = false
var bg_saat_ini: String = "" 

# [BARU] Variabel untuk mengingat status visual dari baris sebelumnya
var mode_layout_saat_ini: String = "satu"
var fokus_saat_ini: String = "kiri"

func _ready():
	hide()
	node_hint.hide()
	bg_gambar.hide()

func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []) -> void:
	resource_dialog = dialogue_resource
	show()
	efek_blur.show() 
	_lanjutkan_dialog(title)

func _lanjutkan_dialog(next_id: String) -> void:
	var baris_dialog = await resource_dialog.get_next_dialogue_line(next_id)
	
	if not baris_dialog:
		queue_free()
		return
		
	is_waiting_for_input = false
	
	label_nama.text = tr(baris_dialog.character, "dialogue")
	label_nama.visible = not baris_dialog.character.is_empty()
	
	_atur_visual_karakter(baris_dialog)
	
	label_teks.dialogue_line = baris_dialog
	label_teks.show()
	label_teks.type_out()
	await label_teks.finished_typing
	
	is_waiting_for_input = true

func _atur_visual_karakter(baris_dialog: DialogueLine) -> void:
	# [DIHAPUS] Kita tidak lagi menyembunyikan portret kiri, kanan, tengah di sini secara otomatis
	
	var tampilkan_hint = false # Hint tetap di-reset tiap baris (harus dipanggil eksplisit)
	
	var tags_to_process = baris_dialog.tags.duplicate()
	
	if "#" in baris_dialog.text:
		var bagian = baris_dialog.text.split("#")
		baris_dialog.text = bagian[0].strip_edges() 
		
		for i in range(1, bagian.size()):
			tags_to_process.append(bagian[i].strip_edges())
	
	# Membaca tag 
	for tag in tags_to_process:
		if tag.begins_with("layout="):
			mode_layout_saat_ini = tag.split("=")[1]
		elif tag.begins_with("fokus="): 
			fokus_saat_ini = tag.split("=")[1]
		elif tag == "hint": 
			tampilkan_hint = true
		elif tag.begins_with("bg="): 
			var nama_bg = tag.split("=")[1]
			if nama_bg == "none" or nama_bg == "kosong":
				bg_saat_ini = ""
				bg_gambar.hide()
			else:
				bg_saat_ini = nama_bg
				var tex_bg = load(PATH_BG + nama_bg + ".png")
				if tex_bg: 
					bg_gambar.texture = tex_bg
					bg_gambar.show()
		# [BARU] Menambahkan fitur menghapus karakter jika diberi tag "none"
		elif tag.begins_with("kiri="):
			var nama_file = tag.split("=")[1]
			if nama_file == "none":
				portret_kiri.texture = null
			else:
				var tex = load(PATH_KARAKTER + nama_file + ".png")
				if tex: portret_kiri.texture = tex
		elif tag.begins_with("kanan="):
			var nama_file = tag.split("=")[1]
			if nama_file == "none":
				portret_kanan.texture = null
			else:
				var tex = load(PATH_KARAKTER + nama_file + ".png")
				if tex: portret_kanan.texture = tex
		elif tag.begins_with("tengah="):
			var nama_file = tag.split("=")[1]
			if nama_file == "none":
				portret_tengah.texture = null
			else:
				var tex = load(PATH_KARAKTER + nama_file + ".png")
				if tex: portret_tengah.texture = tex

	# Menampilkan gambar karakter berdasarkan layout SAAT INI yang terekam
	if mode_layout_saat_ini == "dua":
		portret_tengah.hide() # Sembunyikan yang tengah
		
		if portret_kiri.texture != null: portret_kiri.show()
		if portret_kanan.texture != null: portret_kanan.show()
		
		if fokus_saat_ini == "kanan":
			portret_kiri.modulate = Color(0.5, 0.5, 0.5, 1) 
			portret_kanan.modulate = Color(1, 1, 1, 1)      
		elif fokus_saat_ini == "kiri":
			portret_kiri.modulate = Color(1, 1, 1, 1)       
			portret_kanan.modulate = Color(0.5, 0.5, 0.5, 1)  
		else:
			portret_kiri.modulate = Color(1, 1, 1, 1)
			portret_kanan.modulate = Color(1, 1, 1, 1)
			
	elif mode_layout_saat_ini == "satu":
		portret_kiri.hide()
		portret_kanan.hide()
		
		if portret_tengah.texture != null: portret_tengah.show()
		portret_tengah.modulate = Color(1, 1, 1, 1)
		
	# Memunculkan UI Hint
	if tampilkan_hint:
		if GlobalData.hint_gambar_kiri:
			hint_gambar1.texture = GlobalData.hint_gambar_kiri
		if GlobalData.hint_gambar_kanan:
			hint_gambar2.texture = GlobalData.hint_gambar_kanan
		node_hint.show()
	else:
		node_hint.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	var ditekan = event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed())
	
	if ditekan:
		get_viewport().set_input_as_handled()
		if label_teks.is_typing:
			label_teks.skip_typing()
		elif is_waiting_for_input:
			_lanjutkan_dialog(label_teks.dialogue_line.next_id)
