extends Area2D

var kecepatan_jatuh: float = 250.0
var id_warna: int = 0 

@onready var sprite = $Sprite2D

func setup(warna: Color, id: int, kecepatan: float):
	id_warna = id
	kecepatan_jatuh = kecepatan
	# Warnai kancing placeholder yang putih menjadi warna acak
	sprite.modulate = warna

func _process(delta):
	position.y += kecepatan_jatuh * delta

# Hubungkan sinyal screen_exited dari VisibleOnScreenNotifier2D ke fungsi ini
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free() # Hapus kancing dari memori kalau tidak tertangkap
