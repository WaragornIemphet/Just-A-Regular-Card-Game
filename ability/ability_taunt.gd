extends BaseAbility

@export var debuff_duration: int = 2

func execute(user_card, target_card, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false
		
	var hit_count = 0
	var all_cards = manager.get_tree().get_nodes_in_group("cards")
	
	# Scan the board for the opposing team
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			# This ensures if YOU use it, it hits enemies. If AI uses it, it hits YOU!
			if c.is_player_card != user_card.is_player_card and c.row == c.Row.FRONTLINE:
				
				if c.debuffs != null:
					c.debuffs.apply_taunt(debuff_duration, user_card)
					hit_count += 1
				else:
					manager.log_event("⚠️ ERROR: " + c.card_name + " ignored Taunt! (Missing DebuffManager node)")
					
	if hit_count > 0:
		manager.log_event("📢 " + user_card.card_name + " used " + ability_name + " and taunted " + str(hit_count) + " enemies for " + str(debuff_duration) + " turns!")
	else:
		manager.log_event("📢 " + user_card.card_name + " shouted, but no one was on the frontline!")
		
	current_cooldown = max_cooldown
	return true
