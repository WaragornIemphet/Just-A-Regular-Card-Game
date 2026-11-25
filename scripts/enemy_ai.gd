extends Node

@onready var manager = get_parent()

func initial_draw():
	manager.log_event("--- AI TACTICAL DEPLOYMENT ---")
	var deck_manager = manager.get_node_or_null("DeckManager")
	if deck_manager == null: return
		
	for i in range(5):
		var drawn_scene = deck_manager.draw_card()
		if drawn_scene != null:
			var new_card = drawn_scene.instantiate()
			new_card.is_player_card = false
			new_card.row = new_card.Row.HAND
			new_card.current_slot = "eh" 
			manager.add_child(new_card)
			var eh_anchor = manager.get_node("Board").get_node_or_null("eh")
			if eh_anchor: new_card.global_position = eh_anchor.global_position
			new_card.hide() 
			
	if manager.has_method("update_ai_hand_visuals"): manager.update_ai_hand_visuals() 
	_deploy_from_hand()

func execute_turn():
	manager.log_event("\n--- ENEMY AI TURN STARTED ---")
	await get_tree().create_timer(1.0).timeout 
	
	if manager.current_round == 1 and not manager.player_went_first:
		manager.log_event("🤖 AI goes first! Skipping opening draw.")
	else:
		var deck_manager = manager.get_node_or_null("DeckManager")
		if deck_manager != null:
			var ai_draws_left = 4
			var ai_cards_drawn = 0
			
			while ai_draws_left > 0:
				var ai_hand_size = 0
				var all_c = get_tree().get_nodes_in_group("cards")
				for c in all_c:
					if is_instance_valid(c) and not c.is_queued_for_deletion() and not c.is_player_card and c.current_slot == "eh":
						ai_hand_size += 1
						
				if ai_hand_size >= 6:
					manager.log_event("🤖 AI hand is full! Pausing draw.")
					break
					
				var drawn_scene = deck_manager.draw_card()
				if drawn_scene != null:
					var new_card = drawn_scene.instantiate()
					new_card.is_player_card = false 
					new_card.row = new_card.Row.HAND 
					new_card.current_slot = "eh" 
					manager.add_child(new_card)
					
					var eh_anchor = manager.get_node("Board").get_node_or_null("eh")
					if eh_anchor: new_card.global_position = eh_anchor.global_position
					new_card.hide() 
					
					ai_draws_left -= 1
					ai_cards_drawn += 1
				else:
					manager.log_event("🤖 AI attempted to draw, but the Global Deck is empty!")
					break
			
			if ai_cards_drawn > 0:
				if manager.has_method("update_ai_hand_visuals"):
					manager.update_ai_hand_visuals()
				manager.log_event("🤖 AI drew " + str(ai_cards_drawn) + " cards!")

	await _deploy_from_hand()
			
	var all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			if not card.is_player_card: card.reset_action()
				
	await get_tree().create_timer(1.2).timeout

	var ai_frontline = []
	var ai_reserve = []
	var player_frontline = []
	
	all_cards = get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if not c.is_player_card:
				if not ("is_tower" in c and c.is_tower):
					if c.row == c.Row.FRONTLINE: ai_frontline.append(c)
					elif c.row == c.Row.RESERVE: ai_reserve.append(c)
			elif c.is_player_card and c.row == c.Row.FRONTLINE:
				player_frontline.append(c)
				
	var swapped_this_turn = false
	var synergy_manager = manager.get_node_or_null("SynergyManager")
	
	for front_card in ai_frontline:
		if swapped_this_turn: break
		if front_card.debuffs != null and front_card.debuffs.is_wet(): continue
		var is_disabled = front_card.debuffs != null and (front_card.debuffs.is_disabled() or front_card.debuffs.stun_duration > 0 or front_card.debuffs.freeze_duration > 0)
		if is_disabled:
			for res_card in ai_reserve:
				if res_card.debuffs != null and res_card.debuffs.is_wet(): continue
				if not _is_artillery(res_card):
					manager.log_event("🧠 AI TACTICS: Relieving incapacitated " + front_card.card_name + " with " + res_card.card_name + "!")
					manager.swap_cards(front_card, res_card)
					swapped_this_turn = true
					break

	if not swapped_this_turn:
		for front_card in ai_frontline:
			if swapped_this_turn: break
			if front_card.debuffs != null and front_card.debuffs.is_wet(): continue
			if _is_artillery(front_card):
				for res_card in ai_reserve:
					if res_card.debuffs != null and res_card.debuffs.is_wet(): continue
					if not _is_artillery(res_card):
						manager.log_event("🧠 AI TACTICS: Swapping Artillery " + front_card.card_name + " to the Reserve!")
						manager.swap_cards(front_card, res_card)
						swapped_this_turn = true
						break

	if not swapped_this_turn and synergy_manager != null:
		var best_reserve = null
		var highest_synergy_multiplier = 1.0
		
		for res_card in ai_reserve:
			if res_card.debuffs != null and res_card.debuffs.is_wet(): continue
			if _is_artillery(res_card): continue
			var res_dmg_type = res_card.outgoing_damage_type
			if res_card.base_ignore_def and res_dmg_type == "normal": res_dmg_type = "pierce"
			
			for p_card in player_frontline:
				var sim_dmg = synergy_manager.calculate_synergy_damage(res_card, p_card, res_card.attack_power, res_dmg_type)
				var multiplier = float(sim_dmg) / float(max(1, res_card.attack_power))
				if multiplier > highest_synergy_multiplier:
					highest_synergy_multiplier = multiplier
					best_reserve = res_card
					
		if best_reserve != null:
			var swap_target = null
			for front_card in ai_frontline:
				if front_card.debuffs != null and front_card.debuffs.is_wet(): continue
				if _is_artillery(front_card): continue
				
				var front_dmg_type = front_card.outgoing_damage_type
				if front_card.base_ignore_def and front_dmg_type == "normal": front_dmg_type = "pierce"
				
				var has_good_synergy = false
				for p_card in player_frontline:
					var sim_dmg = synergy_manager.calculate_synergy_damage(front_card, p_card, front_card.attack_power, front_dmg_type)
					if sim_dmg > front_card.attack_power:
						has_good_synergy = true
						break
				
				if not has_good_synergy:
					swap_target = front_card
					break
					
			if swap_target != null:
				manager.log_event("🧠 AI TACTICS: Perfect counter detected! Bringing " + best_reserve.card_name + " to the front!")
				manager.swap_cards(swap_target, best_reserve)
				swapped_this_turn = true

	if swapped_this_turn: await get_tree().create_timer(1.0).timeout

	var alive_enemies = 0
	all_cards = get_tree().get_nodes_in_group("cards")
	for card in all_cards:
		if is_instance_valid(card) and not card.is_queued_for_deletion() and not card.is_player_card:
			var can_act_here = (card.row == card.Row.FRONTLINE) or _is_artillery(card) or ("is_tower" in card and card.is_tower) or (card.row == card.Row.HYBRID)
			if can_act_here and not (card.debuffs != null and card.debuffs.is_disabled()):
				if card.debuffs != null and card.debuffs.is_slowed(): manager.log_event("🐢 " + card.card_name + " is slowed! No AP generated.")
				else: alive_enemies += 1
				
	manager.actions_left = min(manager.max_actions_per_turn, alive_enemies)

	var active_combo_attacker = null

	while manager.actions_left > 0:
		if "is_game_over" in manager and manager.is_game_over:
			manager.log_event("🛑 MATCH OVER! AI ceases fire.")
			break 
			
		var ready_attackers = []
		var valid_targets = []
		
		all_cards = get_tree().get_nodes_in_group("cards")
		
		var active_player_defenders = 0
		var valid_player_slots = ["pf1", "pf2", "pf3", "pf4", "pr1", "phy1", "phy2"]
		
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion() and c.is_player_card:
				if c.current_slot in valid_player_slots:
					var c_is_tower = "is_tower" in c and c.is_tower
					var c_is_trap = "is_trap" in c and c.is_trap
					
					var is_alive = true
					if "health" in c and c.health <= 0:
						is_alive = false
						
					if not c_is_tower and not c_is_trap and is_alive:
						active_player_defenders += 1
		
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				var is_disabled = c.debuffs != null and c.debuffs.is_disabled()
				if not is_disabled:
					if c.is_player_card:
						var is_p_tower = "is_tower" in c and c.is_tower
						var is_p_trap = "is_trap" in c and c.is_trap
						
						if is_p_trap: continue 
						
						if c.row == c.Row.FRONTLINE or c.row == c.Row.HYBRID or (is_p_tower and active_player_defenders <= 1):
							valid_targets.append(c)
							
					elif not c.is_player_card and not c.has_acted and c.row != c.Row.HAND:
						var is_on_cd = "current_attack_cooldown" in c and c.current_attack_cooldown > 0
						
						var has_available_mode = false
						var mode_node = c.get_node_or_null("ModeManager")
						if mode_node != null and "mode_cooldowns" in mode_node:
							for cd in mode_node.mode_cooldowns:
								if cd <= 0:
									has_available_mode = true
									break
									
						if not is_on_cd or has_available_mode:
							var is_ai_tower = "is_tower" in c and c.is_tower
							if c.row == c.Row.FRONTLINE or c.row == c.Row.HYBRID or _is_artillery(c) or is_ai_tower:
								ready_attackers.append(c)
		
		if ready_attackers.size() == 0 or valid_targets.size() == 0: break
			
		var attacker = null
		
		if is_instance_valid(active_combo_attacker) and not active_combo_attacker.has_acted:
			attacker = active_combo_attacker
		else:
			attacker = ready_attackers.pick_random()
			
		var target = null
		
		var is_blind = attacker.debuffs != null and attacker.debuffs.is_blind()
		var is_confused = attacker.debuffs != null and attacker.debuffs.is_confused()
		
		if is_blind:
			var can_use_untargeted = false
			if attacker.ability_node != null and not attacker.ability_node.has_been_used and attacker.ability_node.current_cooldown <= 0:
				if "requires_target" in attacker.ability_node and not attacker.ability_node.requires_target: can_use_untargeted = true
			
			if not can_use_untargeted:
				manager.log_event("🕶️ " + attacker.card_name + " is BLINDED and skips their turn!")
				attacker.exhaust()
				manager.actions_left -= 1
				active_combo_attacker = null
				await get_tree().create_timer(0.5).timeout
				continue
				
		if not is_blind:
			if is_confused:
				manager.log_event("🌀 " + attacker.card_name + " is CONFUSED!")
				var board_targets = []
				for c in all_cards:
					if is_instance_valid(c) and not c.is_queued_for_deletion() and c.row != c.Row.HAND and c != attacker: board_targets.append(c)
				if board_targets.size() > 0:
					target = board_targets.pick_random()
					manager.log_event("🌀 They wildly target " + target.card_name + "!")
					
			else:
				if attacker.debuffs != null and attacker.debuffs.is_taunted():
					var taunter = attacker.debuffs.get_taunter()
					if is_instance_valid(taunter) and taunter.row == taunter.Row.FRONTLINE:
						target = taunter
						manager.log_event("💢 " + attacker.card_name + " is enraged and FORCED to target " + taunter.card_name + "!")
					else: attacker.debuffs.clear_taunt()
						
				if target == null:
					var highest_score = -1.0
					var best_target = null
					var best_mode_idx = -1
					
					var mode_manager = attacker.get_node_or_null("ModeManager")
					var total_modes = 1
					var start_mode_idx = 0
					
					if mode_manager != null: 
						total_modes = mode_manager.alternate_modes.size() + 1
						start_mode_idx = mode_manager.current_index
					
					for m_idx in range(total_modes):
						
						var skip_scoring = false
						
						if "current_attack_cooldown" in attacker and attacker.current_attack_cooldown > 0:
							skip_scoring = true
							
						if mode_manager != null and "exhaust_only_after_all_modes" in mode_manager and mode_manager.exhaust_only_after_all_modes:
							if mode_manager.current_index in mode_manager.modes_attacked_this_turn:
								skip_scoring = true
						
						if not skip_scoring:
							var ai_dmg_type = attacker.outgoing_damage_type
							if attacker.base_ignore_def and ai_dmg_type == "normal": ai_dmg_type = "pierce"
								
							for t in valid_targets:
								if not manager.can_target_domain(attacker, t):
									continue
									
								var synergy_multiplier = 1.0
								if synergy_manager != null:
									if is_instance_valid(t) and not t.is_queued_for_deletion():
										var sim_dmg = synergy_manager.calculate_synergy_damage(attacker, t, attacker.attack_power, ai_dmg_type)
										synergy_multiplier = float(sim_dmg) / float(max(1, attacker.attack_power))
								
								var target_hp = t.tower_hp if ("is_tower" in t and t.is_tower) else t.health
								var threat = (t.attack_power * 2.0) + (target_hp * 0.5)
								var final_score = threat * synergy_multiplier
								
								if target_hp <= (attacker.attack_power * synergy_multiplier): final_score += 50 
								
								if attacker.base_ignore_def and ("defense" in t and t.defense > 0): 
									final_score += 150 
									
								var slot = t.current_slot
								if attacker.splash_damage and slot.length() >= 3:
									var prefix = slot.substr(0, 2)
									var num = int(slot.substr(2, 1))
									if manager.get_card_in_slot(prefix + str(num - 1)) != null or manager.get_card_in_slot(prefix + str(num + 1)) != null:
										final_score += 100 
								
								if final_score > highest_score:
									highest_score = final_score
									best_target = t
									if mode_manager != null: best_mode_idx = mode_manager.current_index
									
						if mode_manager != null: mode_manager.cycle_mode(attacker)
							
					if best_target != null:
						target = best_target
						
						if mode_manager != null and best_mode_idx != -1:
							while mode_manager.current_index != best_mode_idx:
								mode_manager.cycle_mode(attacker)
								
							if mode_manager.current_index != start_mode_idx:
								var mode_name_str = "Unknown Mode"
								if mode_manager.current_index == 0:
									mode_name_str = attacker.base_mode_name if "base_mode_name" in attacker else "Base Form"
								else:
									var alt_index = mode_manager.current_index - 1
									if alt_index >= 0 and alt_index < mode_manager.alternate_modes.size():
										var current_mode_data = mode_manager.alternate_modes[alt_index]
										if "mode_name" in current_mode_data and current_mode_data.mode_name != "":
											mode_name_str = current_mode_data.mode_name
											
								attacker.show_floating_text("🔄 " + mode_name_str, Color.CYAN)
								if attacker.has_method("buff_animation"): attacker.buff_animation()
								manager.log_event("🧠 AI TACTICS: " + attacker.card_name + " shifted to [" + mode_name_str + "] for optimal engagement!")
								await get_tree().create_timer(0.6).timeout
								
						if not is_instance_valid(attacker) or attacker.is_queued_for_deletion():
							manager.actions_left -= 1
							active_combo_attacker = null
							continue # Skip the rest of this loop!
							
						if not is_instance_valid(target) or target.is_queued_for_deletion():
							continue # Target died to the void beam, pick a new one!
								
						if synergy_manager != null:
							var check_dmg = synergy_manager.calculate_synergy_damage(attacker, target, attacker.attack_power, attacker.outgoing_damage_type)
							if check_dmg > attacker.attack_power:
								manager.log_event("🎯 AI TACTICS: " + attacker.card_name + " exploits a synergy weakness on " + target.card_name + "!")
					else:
						if mode_manager != null:
							while mode_manager.current_index != start_mode_idx:
								mode_manager.cycle_mode(attacker)

			if target == null:
				manager.log_event("⚠️ AI couldn't find a valid target! (Blocked by Domain, Range, or Cooldowns). Skipping.")
				attacker.exhaust()
				manager.actions_left -= 1
				active_combo_attacker = null
				await get_tree().create_timer(0.5).timeout
				continue

		var ability_used_and_ended_turn = false
		var is_taunted = attacker.debuffs != null and attacker.debuffs.is_taunted()

		if attacker.ability_node != null and not is_taunted:
			var ability = attacker.ability_node
			if ability.current_cooldown <= 0 and not ability.has_been_used:
				var script_path = ability.get_script().resource_path.get_file()
				var should_use = true

				if "lifesteal" in script_path or "heal" in script_path:
					if attacker.health >= attacker.max_health:
						should_use = false
						manager.log_event("🧠 AI saves heal ability (HP is full).")

				if should_use:
					var ability_target = target if ability.requires_target else null
					var success = await ability.execute(attacker, ability_target, manager)

					if success:
						if ability.is_free_action:
							manager.log_event("🤖 AI used a Free Action! Still preparing to attack...")
							await get_tree().create_timer(0.5).timeout
						else:
							attacker.exhaust()
							manager.actions_left -= 1
							ability_used_and_ended_turn = true
							active_combo_attacker = null
							manager.log_event("🤖 AI used an Action Ability! Actions left: " + str(manager.actions_left))
							await get_tree().create_timer(0.6).timeout
					else: ability.has_been_used = true 

		if not is_instance_valid(attacker) or attacker.is_queued_for_deletion():
			manager.actions_left -= 1
			active_combo_attacker = null
			continue
			
		if not ability_used_and_ended_turn and (not is_instance_valid(target) or target.is_queued_for_deletion()):
			continue # Target melted in the background, loop again to pick a new one

		var end_turn_delay = 1.2
		
		if not ability_used_and_ended_turn:
			
			if is_blind:
				manager.log_event("🕶️ " + attacker.card_name + " is BLINDED and cannot attack!")
				attacker.exhaust()
				manager.actions_left -= 1
				active_combo_attacker = null
				await get_tree().create_timer(0.5).timeout
				continue
				
			if attacker.attack_times <= 0:
				manager.log_event("🤖 " + attacker.card_name + " has no basic attacks. Turn skipped.")
				attacker.exhaust()
				manager.actions_left -= 1
				active_combo_attacker = null
				await get_tree().create_timer(0.5).timeout
				continue 
				
			var target_is_tower = "is_tower" in target and target.is_tower
			
			var bursts = 1
			if "burst_count" in attacker: bursts = attacker.burst_count
			var b_delay = 0.2
			if "burst_delay" in attacker: b_delay = attacker.burst_delay
			
			if target_is_tower:
				bursts = 1

			manager.play_attack_sound(attacker)

			for b_idx in range(bursts):
				if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): break
				if not is_instance_valid(target) or target.is_queued_for_deletion(): break
			
				var raw_damage = attacker.attack_power
				var is_crit = (randi() % 100) < attacker.crit_chance
				if is_crit:
					raw_damage = int(raw_damage * attacker.crit_multiplier)
				
				var ai_dmg_type = attacker.outgoing_damage_type
				if attacker.base_ignore_def and ai_dmg_type == "normal": ai_dmg_type = "pierce"
				
				var terrain_hit_chance = manager.calculate_terrain_hit_chance(attacker, target)
				var is_miss = (randi() % 100) >= terrain_hit_chance
				
				var main_target_dmg = raw_damage
				
				if is_miss:
					main_target_dmg = -1
				else:
					if synergy_manager != null:
						main_target_dmg = synergy_manager.calculate_synergy_damage(attacker, target, raw_damage, ai_dmg_type)
				
				attacker.attack_bump(target.global_position)
				
				if "attack_vfx" in attacker and attacker.attack_vfx != "None":
					var vfx_manager = manager.get_node_or_null("VFXManager")
					if vfx_manager:
						vfx_manager.play_vfx(attacker.attack_vfx, target.global_position)
				
				await get_tree().create_timer(0.1).timeout
				
				if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): break
				if not is_instance_valid(target) or target.is_queued_for_deletion(): break

				if main_target_dmg >= 0:
					if is_crit:
						manager.log_event("⚡ AI CRITICAL HIT! " + attacker.card_name + " deals " + str(main_target_dmg) + " DMG!")
						target.show_floating_text("CRIT!", Color.YELLOW)
					else:
						manager.log_event("⚔️ AI's " + attacker.card_name + " attacks " + target.card_name + " for " + str(main_target_dmg) + " DMG.")

					var hit_landed = target.take_damage(main_target_dmg, ai_dmg_type, attacker)
					
					if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): break
					if not is_instance_valid(target) or target.is_queued_for_deletion(): break
					
					var force_chain = attacker.passives != null and attacker.passives.has_node("PassiveMadeInHeaven")
					if (hit_landed or force_chain) and attacker.passives != null and attacker.passives.has_method("trigger_attack"):
						attacker.passives.trigger_attack(target, main_target_dmg)
					
					if "splash_damage" in attacker and attacker.splash_damage:
						var slot = target.current_slot
						if slot.length() >= 3:
							var prefix = slot.substr(0, 2)
							var num = int(slot.substr(2, 1))
							
							var adj1 = manager.get_card_in_slot(prefix + str(num - 1))
							if adj1:
								var splash_dmg1 = raw_damage
								var splash_chance1 = manager.calculate_terrain_hit_chance(attacker, adj1)
								
								if (randi() % 100) >= splash_chance1:
									manager.log_event("💨 AI Splash MISSED " + adj1.card_name + "!")
									adj1.show_floating_text("Miss!", Color.GRAY)
								else:
									if synergy_manager != null:
										splash_dmg1 = synergy_manager.calculate_synergy_damage(attacker, adj1, raw_damage, ai_dmg_type)
									if splash_dmg1 >= 0:
										adj1.take_damage(splash_dmg1, ai_dmg_type, attacker)
									
							var adj2 = manager.get_card_in_slot(prefix + str(num + 1))
							if adj2:
								var splash_dmg2 = raw_damage
								var splash_chance2 = manager.calculate_terrain_hit_chance(attacker, adj2)
								
								if (randi() % 100) >= splash_chance2:
									manager.log_event("💨 AI Splash MISSED " + adj2.card_name + "!")
									adj2.show_floating_text("Miss!", Color.GRAY)
								else:
									if synergy_manager != null:
										splash_dmg2 = synergy_manager.calculate_synergy_damage(attacker, adj2, raw_damage, ai_dmg_type)
									if splash_dmg2 >= 0:
										adj2.take_damage(splash_dmg2, ai_dmg_type, attacker)
				else:
					manager.log_event("💨 AI's " + attacker.card_name + " MISSED " + target.card_name + "!")
					target.show_floating_text("Miss!", Color.GRAY)
				
				if b_idx < bursts - 1:
					await get_tree().create_timer(b_delay).timeout

			if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
				attacker.attacks_performed += 1
				var target_dead = not is_instance_valid(target) or target.is_queued_for_deletion()
				
				if attacker.attacks_performed >= attacker.attack_times or (valid_targets.size() <= 1 and target_dead) or target_is_tower:
					if target_is_tower and attacker.attacks_performed < attacker.attack_times:
						manager.log_event("🤖 " + attacker.card_name + " hit a tower!")
					
					if "max_attack_cooldown" in attacker and attacker.max_attack_cooldown > 0:
						attacker.current_attack_cooldown = attacker.max_attack_cooldown
						
					var ai_mode = attacker.get_node_or_null("ModeManager")
					if ai_mode != null and "exhaust_only_after_all_modes" in ai_mode and ai_mode.exhaust_only_after_all_modes:
						ai_mode.mark_current_mode_used()
						
						if ai_mode.has_used_all_modes():
							if not attacker.has_acted: attacker.exhaust()
							active_combo_attacker = null
						else:
							attacker.attacks_performed = 0 
							attacker.modulate = Color(1.0, 1.0, 1.0, 1.0) 
							active_combo_attacker = attacker # Forces the AI loop to pick him again!
							manager.log_event("🔄 AI's " + attacker.card_name + " prepares to fire again in a different mode!")
					else:
						if not attacker.has_acted: attacker.exhaust()
						active_combo_attacker = null
						
					manager.actions_left -= 1
				else:
					active_combo_attacker = attacker
					
					if attacker.attack_times > 4:
						end_turn_delay = 0.15 
					elif attacker.attack_times > 1:
						end_turn_delay = 0.5 
			else:
				manager.actions_left -= 1
				active_combo_attacker = null
					
		await get_tree().create_timer(end_turn_delay).timeout
		
	manager.log_event("--- ENEMY AI TURN ENDED ---")
	manager.start_player_turn()
	
func _deploy_from_hand():
	var all_cards = get_tree().get_nodes_in_group("cards")
	var hidden_ai_cards = []
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if not c.is_player_card and c.current_slot == "eh": hidden_ai_cards.append(c)
				
	var sorted_hand = []
	for c in hidden_ai_cards:
		if _is_artillery(c): sorted_hand.push_front(c)
		else: sorted_hand.push_back(c)

	for card in sorted_hand:
		if is_instance_valid(card) and not card.is_queued_for_deletion():
			var target_slot = get_valid_deploy_slot(card)
			
			if target_slot != "":
				card.current_slot = target_slot
				
				if "is_hybrid" in card and card.is_hybrid: card.row = card.Row.HYBRID
				elif "ef" in target_slot: card.row = card.Row.FRONTLINE
				else: card.row = card.Row.RESERVE
				
				card.show()
				var anchor = manager.get_node("Board").get_node_or_null(target_slot)
				if anchor:
					if card.has_method("move_to_anchor"): card.move_to_anchor(anchor.global_position)
					else: card.global_position = anchor.global_position
						
				manager._connect_card_signals(card)
				manager.log_event("🤖 AI deployed " + card.card_name + " from its hand!")
				
				if manager.has_method("update_ai_hand_visuals"): manager.update_ai_hand_visuals() 
				await get_tree().create_timer(0.6).timeout

func get_valid_deploy_slot(card_node) -> String:
	var all_cards = get_tree().get_nodes_in_group("cards")
	var filled_slots = []
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and not c.is_player_card:
			filled_slots.append(c.current_slot)
			
	if "is_tower" in card_node and card_node.is_tower:
		if not "et" in filled_slots: return "et"
		return "" 
		
	if "is_hybrid" in card_node and card_node.is_hybrid:
		if not "ehy1" in filled_slots: return "ehy1"
		if not "ehy2" in filled_slots: return "ehy2"
		return "" 
		
	if _is_artillery(card_node) and not "er1" in filled_slots: return "er1" 
		
	var possible_slots = ["ef1", "ef2", "ef3", "ef4"]
	if not _is_artillery(card_node): possible_slots.append("er1") 
		
	for slot in possible_slots:
		if not slot in filled_slots: return slot
	return ""
	
func _is_artillery(card_node) -> bool:
	if "is_orbital" in card_node and card_node.is_orbital and "is_ranged" in card_node and card_node.is_ranged:
		return true
		
	if card_node.passives != null:
		for p in card_node.passives.get_children():
			if "can_act_from_reserve" in p and p.can_act_from_reserve: return true
	return false
