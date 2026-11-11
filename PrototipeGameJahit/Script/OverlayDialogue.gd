extends CanvasLayer

@onready var nama_karakter = $PanelDialog/NamaKarakter
@onready var teks_dialog = $PanelDialog/TeksDialog
@onready var portret_kiri = $PortretKiri

# FUNGSI WAJIB INI AKAN DIPANGGIL OLEH PLUGIN
func start(dialogue_resource: DialogueResource, title: String, extra_game_states: Array = []):
	DialogueManager.dialogue_ended.connect(_selesai)
	
	# Minta baris pertama ke plugin
	var baris_dialog = await DialogueManager.get_next_dialogue_line(dialogue_resource, title, extra_game_states)
	_tampilkan_baris(baris_dialog)

func _tampilkan_baris(baris: DialogueLine):
	if baris == null:
		queue_free() # Tutup UI jika percakapan habis
		return
		
	nama_karakter.text = baris.character
	teks_dialog.text = baris.text
	
	# --- BACA TAGS DARI FILE DIALOGUE ---
	for tag in baris.tags:
		if tag == "fokus=kiri":
			portret_kiri.modulate = Color(1, 1, 1, 1) # Terang
		elif tag == "fokus=kanan":
			portret_kiri.modulate = Color(0.5, 0.5, 0.5, 1) # Gelap
			
	# Di sini kamu bisa tambahkan animasi ngetik (Typewriter) 
	# atau memunculkan panel Hint jika ada tag #tampilkan_hint

func _input(event):
	if event is InputEventMouseButton and event.is_pressed():
		get_viewport().set_input_as_handled()
		# Minta baris selanjutnya ke plugin saat diklik...
		
# Fungsi ini akan otomatis dipanggil oleh plugin saat percakapan mencapai => END
func _selesai(_resource: DialogueResource):
	queue_free() # Hapus UI Overlay Dialog dari layar
