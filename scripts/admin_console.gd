extends Node
class_name AdminConsole

@onready var manager = get_parent()

func process_command(text: String):
	if not text.begins_with("/"): return
	
	var parts = text.split(" ", false)
	if parts.size() == 0: return
	
	var command = parts[0].to_lower()

	match command:
		"/give":
			if parts.size() < 3:
				manager.log_event("❌ ERROR: Use /give [card_name.tscn] [player/ai]")
				return
				
			var card_file = parts[1]
			if not card_file.ends_with(".tscn"): card_file += ".tscn"
			var target_team = parts[2].to_lower()
			
			var paths_to_try = [
				"res://units/" + card_file,
				"res://hybrids/" + card_file,
				"res://units/hybrids/" + card_file,
				"res://" + card_file,
				"res://scenes/" + card_file,
				"res://cards/" + card_file,
				"res://scenes/cards/" + card_file
			]
			
			var loaded_scene = null
			for path in paths_to_try:
				if ResourceLoader.exists(path):
					loaded_scene = load(path)
					break
					
			if loaded_scene == null:
				manager.log_event("❌ ERROR: CARD NAME DOESN'T MATCH (" + card_file + ")")
				return
				
			var target_is_player = (target_team == "player")
			var new_card = loaded_scene.instantiate()
			new_card.is_player_card = target_is_player
			new_card.row = new_card.Row.HAND
			manager.add_child(new_card)
			
			manager._connect_card_signals(new_card)
			
			if target_is_player:
				new_card.current_slot = "hand"
				new_card.global_position = Vector2(1000, 500)
				manager.log_event("🔧 ADMIN: Spawned " + new_card.card_name + " for PLAYER.")
				if manager.has_node("HandManager"): manager.get_node("HandManager").update_player_hand()
			else:
				new_card.current_slot = "eh"
				new_card.global_position = Vector2(1000, -500)
				manager.log_event("🔧 ADMIN: Spawned " + new_card.card_name + " for AI.")
				if manager.has_method("update_ai_hand_visuals"): manager.update_ai_hand_visuals()

		"/clear":
			if parts.size() < 3:
				manager.log_event("❌ ERROR: Use /clear [board/hand] [player/ai]")
				return
				
			var target_area = parts[1].to_lower()
			var is_player = (parts[2].to_lower() == "player")
			var cleared_count = 0
			
			var all_cards = get_tree().get_nodes_in_group("cards")
			for c in all_cards:
				if is_instance_valid(c) and not c.is_queued_for_deletion() and c.is_player_card == is_player:
					if target_area == "hand" and c.row == c.Row.HAND:
						c.queue_free()
						cleared_count += 1
					elif target_area == "board" and c.row != c.Row.HAND:
						c.queue_free()
						manager._on_card_died(c.current_slot, c.is_player_card)
						cleared_count += 1
						
			manager.log_event("🔧 ADMIN: Cleared " + str(cleared_count) + " cards from " + parts[2].to_upper() + " " + target_area.to_upper() + ".")
			if target_area == "hand":
				if is_player and manager.has_node("HandManager"): manager.get_node("HandManager").update_player_hand()
				elif not is_player and manager.has_method("update_ai_hand_visuals"): manager.update_ai_hand_visuals()

		"/deck":
			if parts.size() < 2:
				manager.log_event("❌ ERROR: Use /deck [reset/draw/draw4] [player/ai]")
				return
			
			var action = parts[1].to_lower()
			
			if action == "reset":
				var dm = manager.get_node_or_null("DeckManager")
				if dm:
					if dm.has_method("build_deck"): dm.build_deck()
					elif dm.has_method("reset"): dm.reset()
					elif dm.has_method("_ready"): dm._ready()
					manager.log_event("🔧 ADMIN: Global deck reset forced!")
				else:
					manager.log_event("❌ ERROR: DeckManager not found.")
					
			elif action == "draw" or action == "draw4":
				if parts.size() < 3:
					manager.log_event("❌ ERROR: Missing target. Use /deck " + action + " [player/ai]")
					return
					
				var is_player = (parts[2].to_lower() == "player")
				var draws = 4 if action == "draw4" else 1
				var drawn = 0
				
				for i in range(draws):
					if is_player:
						if manager.draw_player_card(): drawn += 1
					else:
						var dm = manager.get_node_or_null("DeckManager")
						if dm:
							var drawn_scene = dm.draw_card()
							if drawn_scene:
								var new_card = drawn_scene.instantiate()
								new_card.is_player_card = false
								new_card.row = new_card.Row.HAND
								new_card.current_slot = "eh"
								manager.add_child(new_card)
								manager._connect_card_signals(new_card)
								new_card.global_position = Vector2(1000, -500)
								drawn += 1
								
				manager.log_event("🔧 ADMIN: " + parts[2].to_upper() + " drew " + str(drawn) + " cards.")
				if is_player and manager.has_node("HandManager"): manager.get_node("HandManager").update_player_hand()
				elif not is_player and manager.has_method("update_ai_hand_visuals"): manager.update_ai_hand_visuals()

		"/restart":
			manager.log_event("🔧 ADMIN: Restarting match...")
			get_tree().reload_current_scene()

		"/kill":
			if parts.size() < 3:
				manager.log_event("❌ ERROR: Use /kill [card_name.tscn] [player/ai]")
				return
				
			var target_filename = parts[1].to_lower().replace(".tscn", "")
			var is_player = (parts[2].to_lower() == "player")
			var killed = false
			
			var all_cards = get_tree().get_nodes_in_group("cards")
			for c in all_cards:
				if is_instance_valid(c) and not c.is_queued_for_deletion():
					if c.is_player_card == is_player and c.row != c.Row.HAND:
						
						var actual_filename = c.scene_file_path.get_file().get_basename().to_lower()
						var formatted_name = c.card_name.to_lower().replace(" ", "").replace("_", "")
						
						if actual_filename == target_filename or formatted_name == target_filename:
							manager.log_event("🔧 ADMIN: Executed " + c.card_name + "!")
							c.queue_free()
							manager._on_card_died(c.current_slot, c.is_player_card)
							killed = true
							break # Only kills ONE instance per command
							
			if not killed:
				manager.log_event("❌ ERROR: Could not find '" + target_filename + "' on the " + parts[2].to_upper() + " board.")

		_:
			manager.log_event("❌ ERROR: UNKNOWN ADMIN COMMAND (" + command + ")")
