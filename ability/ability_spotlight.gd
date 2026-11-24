extends BaseAbility

func execute(user_card, target_card, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false

	var frontline_targets = []
	var all_cards = user_card.get_tree().get_nodes_in_group("cards")
	
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			
			if c.row == c.Row.FRONTLINE and c.is_player_card != user_card.is_player_card:
				frontline_targets.append(c)

	
	for target in frontline_targets:
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			
			if target.debuffs != null:
				target.debuffs.apply_blind(2)
				

	
	current_cooldown = max_cooldown
	return true
