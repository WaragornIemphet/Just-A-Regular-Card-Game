extends Control

@onready var roster_grid = $MainSplit/RosterPanel/RosterGrid
@onready var btn_skin = $MainSplit/PlayerPanel/BtnSkin
@onready var btn_lock_in = $MainSplit/RosterPanel/BtnLockIn
@onready var btn_back = $MainSplit/RosterPanel/BtnBack

@onready var p1_portrait = $MainSplit/PlayerPanel/P1Portrait
@onready var p1_name = $MainSplit/PlayerPanel/P1Name
@onready var enemy_portrait = $MainSplit/EnemyPanel/EnemyPortrait
@onready var enemy_name = $MainSplit/EnemyPanel/EnemyName

var available_towers = []
var selected_path: String = ""
var current_skin: int = 0
var max_skins: int = 3 # Let's pretend every tower has 3 skins (0, 1, 2)

func _ready():
	btn_skin.pressed.connect(_on_skin_pressed)
	btn_lock_in.pressed.connect(_on_lock_in_pressed)
	btn_back.pressed.connect(_on_back_pressed)
	
	btn_skin.disabled = true
	btn_lock_in.disabled = true
	
	# Load random mysterious placeholder for AI
	enemy_name.text = "SELECTING..."
	
	# 1. Scan the towers folder
	var dir = DirAccess.open("res://towers/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tscn"):
				available_towers.append("res://towers/" + file_name.replace(".remap", ""))
			file_name = dir.get_next()

	# 2. Generate Grid Buttons
	for tower_path in available_towers:
		var btn = Button.new()
		var nice_name = tower_path.get_file().replace(".tscn", "").capitalize()
		btn.text = nice_name
		btn.custom_minimum_size = Vector2(120, 120) # Make them big squares like KOF!
		btn.add_theme_font_size_override("font_size", 18)
		
		btn.pressed.connect(_preview_tower.bind(tower_path, nice_name))
		roster_grid.add_child(btn)

func _preview_tower(path: String, nice_name: String):
	selected_path = path
	current_skin = 0
	p1_name.text = nice_name
	
	# Enable the buttons now that we picked something
	btn_skin.disabled = false
	btn_lock_in.disabled = false
	update_skin_ui()
	
	# TODO: Later, you can load the actual Sprite2D texture from the .tscn to show in p1_portrait!
	
func _on_skin_pressed():
	current_skin += 1
	if current_skin >= max_skins:
		current_skin = 0
	update_skin_ui()

func update_skin_ui():
	var skin_names = ["Default", "Defense Ministry", "Female", "Naval Officer"]
	btn_skin.text = "👕 Skin: " + skin_names[current_skin]
	
	# (Placeholder visual feedback - you can tint the portrait to see it working!)
	if current_skin == 0: p1_portrait.modulate = Color.WHITE
	elif current_skin == 1: p1_portrait.modulate = Color.GREEN
	elif current_skin == 2: p1_portrait.modulate = Color.MAGENTA

func _on_lock_in_pressed():
	# 1. Save P1 Choice
	GlobalData.player_tower_path = selected_path
	GlobalData.player_tower_skin = current_skin
	
	# 2. AI aggressively picks a random Tower and random Skin!
	if available_towers.size() > 0:
		GlobalData.enemy_tower_path = available_towers.pick_random()
		GlobalData.enemy_tower_skin = randi() % max_skins
		
	# 3. Transition to Battle!
	get_tree().change_scene_to_file("res://jarcg.tscn")

func _on_back_pressed():
	get_tree().change_scene_to_file("res://main_menu.tscn")
