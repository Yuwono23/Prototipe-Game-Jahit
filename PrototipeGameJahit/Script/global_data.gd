extends Node

var total_poin: int = 0

# user:// adalah direktori khusus Godot yang aman untuk menyimpan data 
# dan otomatis didukung di PC maupun Android.
const PATH_SIMPAN = "user://data_pemain.cfg" 

func _ready():
	muat_data()

func tambah_poin(jumlah: int = 1):
	total_poin += jumlah
	print("Menang! Poin bertambah. Total poin sekarang: ", total_poin)
	simpan_data()

func simpan_data():
	var konfigurasi = ConfigFile.new()
	# Menyimpan nilai total_poin ke dalam kategori "Progres"
	konfigurasi.set_value("Progres", "total_poin", total_poin)
	konfigurasi.save(PATH_SIMPAN)

func muat_data():
	var konfigurasi = ConfigFile.new()
	# Cek apakah file save sudah ada sebelumnya
	if konfigurasi.load(PATH_SIMPAN) == OK:
		total_poin = konfigurasi.get_value("Progres", "total_poin", 0)
	else:
		total_poin = 0 # Mulai dari 0 jika ini pertama kali main
