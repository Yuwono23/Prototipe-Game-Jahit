extends CanvasLayer

# --- REFERENSI NODE ---
# Sesuaikan jalurnya ($) jika struktur nodemu sedikit berbeda
@onready var label_nama = $PanelDialog/NamaKarakter
@onready var label_teks = $PanelDialog/TeksDialog # Pastikan ini menggunakan tipe DialogueLabel bawaan plugin
@onready var portret_kiri = $PortretKiri
@onready var portret_kanan = $PortretKanan
@onready var portret_tengah = $PortretTengah

const PATH_KARAKTER = "res://Asset/Placeholder/"

# --- VARIABEL SISTEM ---
var resource_dialog: DialogueResource
var is_waiting_for_input: bool = false

func _ready():
	# Sembunyikan UI di awal sebelum dialog dipanggil
	hide()

# Fungsi utama untuk dipanggil dari Scene Test atau Scene Manager
func start(dialogue_resource: DialogueResource, title: String) -> void:
	resource_dialog = dialogue_resource
	show()
	_lanjutkan_dialog(title)

func _lanjutkan_dialog(next_id: String) -> void:
	# Ambil baris dialog selanjutnya dari file .dialogue
	var baris_dialog = await resource_dialog.get_next_dialogue_line(next_id)
	
	# Jika dialog sudah habis (mencapai => END), tutup dan hapus node ini
	if not baris_dialog:
		queue_free()
		return
		
	is_waiting_for_input = false
	
	# 1. Update Nama Karakter
	label_nama.text = tr(baris_dialog.character, "dialogue")
	label_nama.visible = not baris_dialog.character.is_empty()
	
	# 2. Update Visual Potret DULU (Sekaligus membersihkan tag yang bocor dari teks)
	_atur_visual_karakter(baris_dialog)
	
	# 3. BARU setel ke node TeksDialog agar teks yang sudah bersih yang terketik di layar
	label_teks.dialogue_line = baris_dialog
	label_teks.show()
	label_teks.type_out()
	await label_teks.finished_typing
	
	# Selesai mengetik, tunggu pemain klik/tekan tombol
	is_waiting_for_input = true

func _atur_visual_karakter(baris_dialog: DialogueLine) -> void:
	portret_kiri.hide()
	portret_kanan.hide()
	portret_tengah.hide()
	
	var mode_layout = "satu"
	var fokus_karakter = "kiri" # Default pembicara ada di kiri
	var tags_to_process = baris_dialog.tags.duplicate()
	
	# --- FIX MANUAL PARSING ---
	if "#" in baris_dialog.text:
		var bagian = baris_dialog.text.split("#")
		baris_dialog.text = bagian[0].strip_edges() 
		
		for i in range(1, bagian.size()):
			tags_to_process.append(bagian[i].strip_edges())
	# --------------------------
	
	# Membaca tag dari daftar yang sudah dibersihkan
	for tag in tags_to_process:
		if tag.begins_with("layout="):
			mode_layout = tag.split("=")[1]
		elif tag.begins_with("fokus="):   # [BARU] Membaca tag fokus
			fokus_karakter = tag.split("=")[1]
		elif tag.begins_with("kiri="):
			var nama_file = tag.split("=")[1]
			var tex = load(PATH_KARAKTER + nama_file + ".png")
			if tex: portret_kiri.texture = tex
		elif tag.begins_with("kanan="):
			var nama_file = tag.split("=")[1]
			var tex = load(PATH_KARAKTER + nama_file + ".png")
			if tex: portret_kanan.texture = tex
		elif tag.begins_with("tengah="):
			var nama_file = tag.split("=")[1]
			var tex = load(PATH_KARAKTER + nama_file + ".png")
			if tex: portret_tengah.texture = tex

	# Menampilkan gambar sesuai layout
	if mode_layout == "dua":
		portret_kiri.show()
		portret_kanan.show()
		
		# [BARU] Logika meredupkan karakter berdasarkan Tag Fokus
		if fokus_karakter == "kanan":
			portret_kiri.modulate = Color(0.5, 0.5, 0.5, 1) # Kiri redup
			portret_kanan.modulate = Color(1, 1, 1, 1)      # Kanan terang
		elif fokus_karakter == "kiri":
			portret_kiri.modulate = Color(1, 1, 1, 1)       # Kiri terang
			portret_kanan.modulate = Color(0.5, 0.5, 0.5, 1)  # Kanan redup
		else:
			# Jika tag fokus diisi teks lain (misal #fokus=dua_duanya), keduanya terang
			portret_kiri.modulate = Color(1, 1, 1, 1)
			portret_kanan.modulate = Color(1, 1, 1, 1)
			
	elif mode_layout == "satu":
		portret_tengah.show()
		portret_tengah.modulate = Color(1, 1, 1, 1)

# Menangkap input klik kiri atau tombol spasi/enter
func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
		
	var ditekan = event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed())
	
	if ditekan:
		get_viewport().set_input_as_handled()
		
		# Jika sedang mengetik, langsung tampilkan semua teks (skip animasi)
		if label_teks.is_typing:
			label_teks.skip_typing()
		# Jika sudah selesai mengetik, lanjut ke baris berikutnya
		elif is_waiting_for_input:
			_lanjutkan_dialog(label_teks.dialogue_line.next_id)
