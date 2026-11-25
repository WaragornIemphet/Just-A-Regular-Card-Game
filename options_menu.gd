extends Control

@onready var master_slider = %MasterSlider
@onready var ui_slider = %UISlider
@onready var sfx_slider = %SFXSlider
@onready var music_slider = %MusicSlider

@onready var master_value = %MasterValue
@onready var ui_value = %UIValue
@onready var sfx_value = %SFXValue
@onready var music_value = %MusicValue

@onready var back_button = %BackButton

var bus_master: int
var bus_ui: int
var bus_sfx: int
var bus_music: int

func _ready():
	bus_master = AudioServer.get_bus_index("Master")
	bus_ui = AudioServer.get_bus_index("UI")
	bus_sfx = AudioServer.get_bus_index("SFX")
	bus_music = AudioServer.get_bus_index("Music")
	
	_setup_slider(master_slider, bus_master, master_value)
	_setup_slider(ui_slider, bus_ui, ui_value)
	_setup_slider(sfx_slider, bus_sfx, sfx_value)
	_setup_slider(music_slider, bus_music, music_value)
	
	master_slider.value_changed.connect(_on_volume_changed.bind(bus_master, master_value))
	ui_slider.value_changed.connect(_on_volume_changed.bind(bus_ui, ui_value))
	sfx_slider.value_changed.connect(_on_volume_changed.bind(bus_sfx, sfx_value))
	music_slider.value_changed.connect(_on_volume_changed.bind(bus_music, music_value))
	
	back_button.pressed.connect(_on_back_pressed)

func _setup_slider(slider: HSlider, bus_index: int, value_label: Label):
	var current_db = AudioServer.get_bus_volume_db(bus_index)
	var linear_val = db_to_linear(current_db)
	
	slider.value = linear_val
	value_label.text = str(int(linear_val * 100))

func _on_volume_changed(value: float, bus_index: int, value_label: Label):
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(bus_index, db)
	AudioServer.set_bus_mute(bus_index, value <= 0.001)
	
	value_label.text = str(int(value * 100))

func _on_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
