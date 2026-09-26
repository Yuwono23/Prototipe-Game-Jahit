extends TextureProgressBar

signal waktu_habis

@onready var waktu_internal = $WaktuInternal

# Variabel ini tidak perlu di-export karena minigame akan mengirimkannya
var durasi_maksimal: float = 10.0 
var sedang_berjalan: bool = false

func _ready():
	waktu_internal.timeout.connect(_pada_waktu_habis)
	# Sembunyikan timer saat pertama kali dimuat (akan muncul saat dipanggil start)
	hide()

# Minigame akan memanggil fungsi ini untuk menyalakan timer
func mulai_timer(durasi: float):
	print("KODI CEK: Timer Global berhasil dipanggil! Durasi: ", durasi) # <--- Tambahkan ini
	durasi_maksimal = durasi
	max_value = durasi
	value = durasi
	
	waktu_internal.start(durasi)
	sedang_berjalan = true
	show()

func hentikan_timer():
	waktu_internal.stop()
	sedang_berjalan = false

func _process(_delta):
	# Update visual bar setiap frame
	if sedang_berjalan:
		value = waktu_internal.time_left
		
# Fungsi untuk memotong waktu yang sedang berjalan
func kurangi_waktu(penalti: float):
	if not sedang_berjalan: return
	
	var sisa_waktu = waktu_internal.time_left - penalti
	if sisa_waktu <= 0:
		# Jika setelah dikurangi waktunya habis (minus), panggil fungsi kalah
		waktu_internal.stop()
		_pada_waktu_habis()
	else:
		# Jika masih ada sisa, mulai ulang timer internal dengan sisa waktu baru
		waktu_internal.start(sisa_waktu)
		max_value = durasi_maksimal # Pastikan max_value tetap utuh agar bar tidak loncat

func _pada_waktu_habis():
	sedang_berjalan = false
	value = 0
	waktu_habis.emit() # Beri tahu minigame bahwa waktu sudah habis!
