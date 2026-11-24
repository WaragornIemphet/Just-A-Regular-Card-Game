extends BaseAbility

func execute(attacker, target, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false
		
	manager.log_event("🩸 " + attacker.card_name + " uses " + ability_name + "!")
	
	# --- FIXED: Determine dynamic damage type ---
	var dmg_type = attacker.outgoing_damage_type
	if attacker.base_ignore_def and dmg_type == "normal":
		dmg_type = "pierce"
	
	# --- FIXED: Send the String type and the Attacker Node ---
	target.take_damage(attacker.attack_power, dmg_type, attacker)
	
	# Heal the attacker
	attacker.heal(attacker.attack_power*3)
	
	current_cooldown = max_cooldown
	return true
