extends Node

@onready var battle_logic = get_parent()
@onready var board = $"../Board"

func _ready():
	# call_deferred waits exactly 1 frame to ensure the Board and all anchors
	# are fully loaded and positioned before we try to spawn the Towers!
	call_deferred("spawn_towers")

func spawn_towers():
	# --- PLAYER TOWER ---
	if GlobalData.player_tower_path != "":
		var p_tower_scene = load(GlobalData.player_tower_path)
		if p_tower_scene:
			var p_tower = p_tower_scene.instantiate()
			p_tower.add_to_group("cards") # <--- FIXES VISUAL & HIGHLIGHT BUGS
			p_tower.is_player_card = true
			p_tower.current_slot = "pt"
			p_tower.row = p_tower.Row.RESERVE 
			
			
			battle_logic.add_child(p_tower)
			
			if p_tower.has_method("apply_skin"):
				p_tower.apply_skin(GlobalData.player_tower_skin)
			var anchor = board.get_node_or_null("pt")
			if anchor:
				p_tower.global_position = anchor.global_position
				if p_tower.has_method("move_to_anchor"):
					p_tower.move_to_anchor(anchor.global_position)
			battle_logic._connect_card_signals(p_tower)
			
	# --- ENEMY TOWER ---
	if GlobalData.enemy_tower_path != "":
		var e_tower_scene = load(GlobalData.enemy_tower_path)
		if e_tower_scene:
			var e_tower = e_tower_scene.instantiate()
			e_tower.add_to_group("cards") # <--- FIXES VISUAL & HIGHLIGHT BUGS
			e_tower.is_player_card = false
			e_tower.current_slot = "et"
			e_tower.row = e_tower.Row.RESERVE
			
			# --- (Inside Player Tower spawn logic) ---
			battle_logic.add_child(e_tower)
			
			# ---> NEW: APPLY SKIN DATA <---
			if e_tower.has_method("apply_skin"):
				e_tower.apply_skin(GlobalData.enemy_tower_skin)
			var anchor = board.get_node_or_null("et")
			if anchor:
				e_tower.global_position = anchor.global_position
				if e_tower.has_method("move_to_anchor"):
					e_tower.move_to_anchor(anchor.global_position)
			battle_logic._connect_card_signals(e_tower)	
