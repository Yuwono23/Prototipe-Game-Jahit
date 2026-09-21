extends Control

@onready var play_button = $Panel/VBoxContainer/Play
@onready var setting_button =$Panel/VBoxContainer/Setting
@onready var credit_button =$Panel/VBoxContainer/Button


func _ready():
	play_button.pressed.connect(_on_play_pressed)
	setting_button.pressed.connect(_on_setting_pressed)
	credit_button.pressed.connect(_on_credit_pressed)


func _on_play_pressed():
	print("Game Dimulai")
	# get_tree().change_scene_to_file("res://Scene/Level1.tscn")


func _on_setting_pressed():
	get_tree().change_scene_to_file("res://Scene/Setting.tscn")


func _on_credit_pressed():
	print("Credits dibuka")
