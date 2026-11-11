extends Node2D

func _ready():
	# Memberikan sedikit jeda agar game selesai dimuat sebelum dialog muncul
	await get_tree().create_timer(0.5).timeout 
	
	# Panggil hint-nya!
	$HintOverlay.mulai_tampilkan_hint()
