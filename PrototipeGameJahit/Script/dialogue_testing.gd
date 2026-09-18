extends Node 

const FILE_DIALOG = preload("res://Dialogue/cerita_tutorial.dialogue") 

# Sesuaikan dengan nama scene barumu
const BALLOON_SCENE = preload("res://Scene/dialogue_system.tscn") 

func _ready():
	await get_tree().create_timer(0.5).timeout
	_jalankan_tes_dialog()

func _jalankan_tes_dialog():
	var balloon = BALLOON_SCENE.instantiate()
	add_child(balloon)
	
	# Memanggil fungsi start() yang ada di dialogue_system.gd
	balloon.start(FILE_DIALOG, "sebelum_potong")
	
	# Mendeteksi kapan node balloon ini memanggil queue_free() dan terhapus
	balloon.tree_exited.connect(_pada_dialog_selesai)

func _pada_dialog_selesai():
	print("Tes dialog berhasil diselesaikan! Modul siap digabung ke Scene Manager.")
