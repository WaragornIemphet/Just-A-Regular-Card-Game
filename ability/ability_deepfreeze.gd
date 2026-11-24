extends BaseAbility

func execute(attacker, target, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false
		
	manager.log_event(attacker.card_name + " uses " + ability_name + "!")
	
	if target.debuffs != null:
				target.debuffs.apply_freeze(5)
	
	
	current_cooldown = max_cooldown
	return true
