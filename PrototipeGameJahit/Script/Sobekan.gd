extends TextureButton

signal sobekan_ditekan

@onready var penanda = $Penanda
var sudah_ditekan: bool = false

func _ready():
	# Hubungkan sinyal bawaan TextureButton
	pressed.connect(_saat_ditekan)

func _saat_ditekan():
	if sudah_ditekan: return
	
	sudah_ditekan = true
	penanda.show() # Munculkan lingkaran penanda
	
	# Matikan interaksi agar tidak bisa diklik dua kali
	mouse_filter = Control.MOUSE_FILTER_IGNORE 
	
	sobekan_ditekan.emit()
