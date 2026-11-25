extends BaseAbility

func execute(user_card, target_card, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false

	manager.log_event("⚔️ >>> " + user_card.card_name + " unleashes " + ability_name + " on the ENTIRE FRONTLINE! <<<")

	var frontline_targets = []
	var all_cards = user_card.get_tree().get_nodes_in_group("cards")
	
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.row == c.Row.FRONTLINE and c.is_player_card != user_card.is_player_card:
				frontline_targets.append(c)

	for target in frontline_targets:
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			target.take_damage(10, "poison", user_card) 
			
			if target.debuffs != null:
				target.debuffs.apply_disabled(1)
				target.debuffs.apply_poison(1, 10)

	current_cooldown = max_cooldown
	return true
