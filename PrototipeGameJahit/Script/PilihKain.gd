extends Control

# Muncul di Inspector Godot. Masukkan semua tekstur kain ke dalam array ini.
@export var database_kain: Array[Texture2D]

@onready var target_kain = $BingkaiTarget/TargetKain
@onready var wadah = $WadahPilihan
@onready var tombol_kain = wadah.get_children()
var posisi_awal_y_wadah = 0.0
var sudah_memilih = false
var index_jawaban_benar = 0 # Tentukan indeks kain yang benar (0, 1, atau 2)

@onready var timer_game = $Timer
@onready var bar_waktu = $ProgressBar
# Waktu dasar 3 detik, durasi standar untuk microgame bertempo cepat
var durasi_level = 20.0
var tween_hover: Tween # Menyimpan Tween hover agar tidak bentrok

func _ready():
	posisi_awal_y_wadah = wadah.position.y
	# Hubungkan sinyal timeout dari timer secara langsung melalui kode
	timer_game.timeout.connect(_saat_waktu_habis)
	_hubungkan_sinyal()
	_siapkan_ronde_baru() # Panggil fungsi acak saat game mulai

func _process(_delta):
	# Update tampilan bar waktu secara mulus setiap frame selama timer berjalan
	if not timer_game.is_stopped() and not sudah_memilih:
		# Menghitung persentase sisa waktu (0 sampai 100)
		bar_waktu.value = (timer_game.time_left / timer_game.wait_time) * 100.0
		
func _hubungkan_sinyal():
	for i in range(tombol_kain.size()):
		var tombol = tombol_kain[i]
		# Menghubungkan sinyal interaksi secara dinamis
		tombol.mouse_entered.connect(_saat_hover.bind(tombol))
		tombol.mouse_exited.connect(_saat_hover_selesai)
		tombol.pressed.connect(_saat_dipilih.bind(i, tombol))

func _siapkan_ronde_baru():
	# Pastikan ada cukup kain di database untuk mencegah error
	if database_kain.size() < 3:
		push_error("Database butuh minimal 3 tekstur kain!")
		return
		
	# 1. Duplikat array agar data asli tidak hilang saat kita ambil isinya
	var pilihan_tersedia = database_kain.duplicate()
	pilihan_tersedia.shuffle() 
	
	# 2. Ambil 1 kain sebagai target (benar) dan 2 kain salah
	var kain_benar = pilihan_tersedia.pop_back()
	var kain_salah_1 = pilihan_tersedia.pop_back()
	var kain_salah_2 = pilihan_tersedia.pop_back()
	
	# 3. Pasang gambar target di bagian atas layar (TextureRect)
	target_kain.texture = kain_benar
	
	# 4. Gabungkan ketiganya dan acak urutannya untuk ditaruh di tombol
	var daftar_pilihan = [kain_benar, kain_salah_1, kain_salah_2]
	daftar_pilihan.shuffle()
	
	# 5. Terapkan tekstur ke tombol dan catat posisi jawaban yang benar
	for i in range(tombol_kain.size()):
		var tombol = tombol_kain[i] as TextureButton
		tombol.texture_normal = daftar_pilihan[i]
		
		# Jika tekstur tombol ini sama dengan kain target, simpan indeksnya
		if daftar_pilihan[i] == kain_benar:
			index_jawaban_benar = i
		
	# Reset bar dan mulai timer setelah ronde siap dimainkan
	bar_waktu.value = 100.0
	timer_game.start(durasi_level)
			
func _saat_hover(tombol_aktif: TextureButton):
	if sudah_memilih: return
	
	# Matikan animasi hover sebelumnya jika masih berjalan
	if tween_hover and tween_hover.is_valid():
		tween_hover.kill()
		
	tween_hover = create_tween().set_parallel(true)
	for tombol in tombol_kain:
		if tombol == tombol_aktif:
			tween_hover.tween_property(tombol, "position:y", -40.0, 0.1) # Tarik lebih tinggi
		else:
			tween_hover.tween_property(tombol, "position:y", 10.0, 0.1)

func _saat_hover_selesai():
	if sudah_memilih: return
	if tween_hover and tween_hover.is_valid():
		tween_hover.kill()
	tween_hover = create_tween().set_parallel(true)
	for tombol in tombol_kain:
		tween_hover.tween_property(tombol, "position:y", 0.0, 0.15)

func _saat_dipilih(indeks: int, tombol_terpilih: TextureButton):
	if sudah_memilih: return
	sudah_memilih = true
	timer_game.stop() 
	
	# Hentikan gerakan hover yang mungkin masih berjalan
	if tween_hover and tween_hover.is_valid():
		tween_hover.kill()

	# Keluarkan SEMUA tombol dari wadah agar tidak ada yang bergeser merapat
	for tombol in tombol_kain:
		var posisi_global_sekarang = tombol.global_position
		wadah.remove_child(tombol)
		add_child(tombol)
		tombol.global_position = posisi_global_sekarang

	var tween_pilih = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	for tombol in tombol_kain:
		if tombol == tombol_terpilih:
			var posisi_tengah = get_viewport_rect().size / 2.0 - (tombol.size / 2.0)
			tween_pilih.tween_property(tombol, "global_position", posisi_tengah, 0.5)
		else:
			# Jatuhkan kain salah tepat di posisinya saat ini
			tween_pilih.tween_property(tombol, "global_position:y", tombol.global_position.y + 600.0, 0.4).set_trans(Tween.TRANS_SINE)
	
	tween_pilih.chain().tween_callback(_cek_hasil.bind(indeks))

func _saat_waktu_habis():
	if sudah_memilih: return
	sudah_memilih = true
	
	# Visualisasikan bar waktu benar-benar habis
	bar_waktu.value = 0 
	
	# Panggil fungsi cek hasil dengan parameter khusus untuk menandakan 'Kehabisan Waktu'
	_cek_hasil(-1)

func _cek_hasil(indeks: int):
	if indeks == index_jawaban_benar:
		print("BENAR! Tampilkan partikel centang/konfeti.")
	elif indeks == -1:
		print("GAGAL! Waktu habis.")
	else:
		print("SALAH! Tampilkan tanda silang/kain robek.")
