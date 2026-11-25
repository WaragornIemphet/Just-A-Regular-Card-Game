extends BaseAbility

func _init():
	requires_target = false

func execute(user_card, target_card, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event("⏳ " + ability_name + " is reloading for " + str(current_cooldown) + " turns!")
		return false

	manager.log_event(">>> " + user_card.card_name + " Strike incoming! <<<")

	for i in range(3):
		
		var valid_targets = []
		var all_cards = user_card.get_tree().get_nodes_in_group("cards")
		
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				if c.is_player_card != user_card.is_player_card and c.row == c.Row.FRONTLINE:
					valid_targets.append(c)
		
		if valid_targets.size() == 0:
			manager.log_event("The smoke clears... no targets remain for the barrage!")
			break 
			
		var target = valid_targets.pick_random()
		
		var damage_to_deal = user_card.attack_power
		var dmg_type = user_card.outgoing_damage_type
		if user_card.base_ignore_def and dmg_type == "normal":
			dmg_type = "pierce"
			
		var is_crit = (randi() % 100) < user_card.crit_chance
		if is_crit:
			damage_to_deal = int(damage_to_deal * user_card.crit_multiplier)
			manager.log_event("💥 CRIT! Shell #" + str(i+1) + " blasts " + target.card_name + " for " + str(damage_to_deal) + " DMG!")
			target.show_floating_text("CRIT!", Color.YELLOW)
		else:
			manager.log_event("Mortar Shell #" + str(i+1) + " hits " + target.card_name + " for " + str(damage_to_deal) + " DMG.")
			
		var hit_landed = target.take_damage(damage_to_deal, dmg_type, user_card)
		
		if hit_landed and user_card.passives != null:
			user_card.passives.trigger_attack(target, damage_to_deal)
			
		if "splash_damage" in user_card and user_card.splash_damage:
			var slot = target.current_slot 
			if slot.length() >= 3:
				var prefix = slot.substr(0, 2) 
				var num = int(slot.substr(2, 1)) 
				
				var adj1 = manager.get_card_in_slot(prefix + str(num - 1))
				if adj1: 
					manager.log_event("   -> Splash hit " + adj1.card_name + " for " + str(damage_to_deal) + " DMG!")
					adj1.take_damage(damage_to_deal, dmg_type, user_card)
					
				var adj2 = manager.get_card_in_slot(prefix + str(num + 1))
				if adj2: 
					manager.log_event("   -> Splash hit " + adj2.card_name + " for " + str(damage_to_deal) + " DMG!")
					adj2.take_damage(damage_to_deal, dmg_type, user_card)
		
		await user_card.get_tree().create_timer(0.3).timeout

	current_cooldown = max_cooldown
	return true
