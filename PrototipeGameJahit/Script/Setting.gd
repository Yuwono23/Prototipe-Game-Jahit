extends Control

@onready var master_volume = $"Panel/VBoxContainer/Box Master/MasterVolume"
@onready var music_volume = $"Panel/VBoxContainer/Box Music/MusicVolume"
@onready var sfx_volume = $"Panel/VBoxContainer/Box Sfx/SFXVolume"

@onready var resolution = $"Panel/VBoxContainer/Box Resolution/Resolution"
@onready var display = $"Panel/VBoxContainer/Box Display/Display Mode"

@onready var apply_button = $"Panel/VBoxContainer/Box Click/Apply"
@onready var back_button = $"Panel/VBoxContainer/Box Click/Back"

var resolutions = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
]

func _ready():
	# Tombol
	apply_button.pressed.connect(_on_play_pressed)
	back_button.pressed.connect(_on_back_pressed)

	#volume 
	master_volume.value = 100
	music_volume.value = 100
	sfx_volume.value = 100

func _on_play_pressed():
	var selected_resolution = resolutions[resolution.selected]

	DisplayServer.window_set_size(selected_resolution)

	if display.selected == 0:
		# Fullscreen
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN
		)
	else:
		# Windowed
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_WINDOWED
		)


	# =====================
	# AUDIO
	# =====================
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Master"),
		linear_to_db(master_volume.value / 100.0)
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(music_volume.value / 100.0)
	)

	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(sfx_volume.value / 100.0)
	)


func _on_back_pressed():
	get_tree().change_scene_to_file("res://Scene/MainMenu.tscn")
