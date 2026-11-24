extends Control

@onready var btn_singleplayer = $VBoxContainer/BtnSingleplayer
@onready var btn_multiplayer = $VBoxContainer/BtnMultiplayer
@onready var btn_options = $VBoxContainer/BtnOptions
@onready var btn_quit = $VBoxContainer/BtnQuit

func _ready():
	# 1. Connect the buttons
	btn_singleplayer.pressed.connect(_on_singleplayer_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	# 2. Lock the Multiplayer button!
	btn_multiplayer.disabled = true
	btn_multiplayer.text = "Multiplayer 🔒 (Under Construction)"
	
func _on_singleplayer_pressed():
	# Go to the draft screen first!
	get_tree().change_scene_to_file("res://tower_select.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://options_menu.tscn")
	# Later, you can show/hide an Options Panel here

func _on_quit_pressed():
	# Closes the entire application safely
	get_tree().quit()
