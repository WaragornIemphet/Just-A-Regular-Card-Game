extends Node
class_name DeckManager

@export var card_folders: Array[String] = [
	"res://units",
	"res://traps",
	"res://hybrids"
]


var global_pool: Array[PackedScene] = []

func _ready():
	var all_loaded_scenes: Array[PackedScene] = []
	
	for folder in card_folders:
		var scenes_from_folder = load_all_cards(folder)
		all_loaded_scenes.append_array(scenes_from_folder) 
		
	setup_global_deck(all_loaded_scenes)


func load_all_cards(folder_path: String) -> Array[PackedScene]:
	var loaded_cards: Array[PackedScene] = []
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				if file_name.ends_with(".tscn") or file_name.ends_with(".remap"):
					var clean_name = file_name.replace(".remap", "")
					var full_path = folder_path + "/" + clean_name
					
					var scene = load(full_path)
					if scene != null:
						loaded_cards.append(scene)
						
			file_name = dir.get_next()
			
		dir.list_dir_end()
		print("DeckManager loaded ", loaded_cards.size(), " unique cards from ", folder_path)
	else:
		print("DeckManager ERROR: Could not access folder path: ", folder_path)
		
	return loaded_cards


func setup_global_deck(master_card_list: Array[PackedScene]):

	global_pool = master_card_list.duplicate()
	
	global_pool.shuffle()
	print("DECK MANAGER: Global pool scrambled. Total remaining: ", global_pool.size())

func draw_card() -> PackedScene:
	if global_pool.is_empty():
		print("DECK MANAGER: The Global Pool is completely empty! No unique units remain.")
		return null
		

	var drawn_card = global_pool.pop_front()
	
	return drawn_card
