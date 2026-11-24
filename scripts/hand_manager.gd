extends Node

@onready var manager = get_parent()

func update_player_hand():
	var player_hand = []
	
	# 1. Gather all cards currently sitting in the Player's Hand
	var all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.row == c.Row.HAND and c.is_player_card:
				player_hand.append(c)
				
	# 2. Find the marker and align them!
	var ph_marker = manager.get_node("Board/ph")
	if ph_marker != null and player_hand.size() > 0:
		var spacing = 105 # <-- Change this number if cards overlap too much or too little!
		var start_x = ph_marker.global_position.x - ((player_hand.size() - 1) * spacing / 2.0)
		
		for i in range(player_hand.size()):
			var target_pos = Vector2(start_x + (i * spacing), ph_marker.global_position.y)
			
			# Save the overlap order so the hover tween doesn't break it!
			player_hand[i].base_z_index = i 
			player_hand[i].z_index = i
			
			player_hand[i].move_to_anchor(target_pos)
