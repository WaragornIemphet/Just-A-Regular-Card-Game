extends Control

@onready var btn_singleplayer = $VBoxContainer/BtnSingleplayer
@onready var btn_multiplayer = $VBoxContainer/BtnMultiplayer
@onready var btn_options = $VBoxContainer/BtnOptions
@onready var btn_quit = $VBoxContainer/BtnQuit

func _ready():
	btn_singleplayer.pressed.connect(_on_singleplayer_pressed)
	btn_options.pressed.connect(_on_options_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	
	btn_multiplayer.disabled = true
	btn_multiplayer.text = "Multiplayer 🔒 (Under Construction)"
	
func _on_singleplayer_pressed():
	get_tree().change_scene_to_file("res://tower_select.tscn")

func _on_options_pressed():
	get_tree().change_scene_to_file("res://options_menu.tscn")

func _on_quit_pressed():
	get_tree().quit()
