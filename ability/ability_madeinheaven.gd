extends BaseAbility

func execute(user_card, target_card, manager) -> bool:
	manager.log_event("\n⏳ >>> TIME ACCELERATES! " + user_card.card_name + " achieves HEAVEN! <<<")

	# ==========================================
	# 1. TURN ACCELERATION (Play Twice)
	# ==========================================
	var alive_allies = 0
	var all_cards = manager.get_tree().get_nodes_in_group("cards")
	for c in all_cards:
		if is_instance_valid(c) and c.is_player_card == user_card.is_player_card and c.row != c.Row.HAND:
			alive_allies += 1
			
	manager.actions_left += min(manager.max_actions_per_turn, alive_allies)
	manager.current_round += 1
	manager.ui_turn_label.text = "--- ROUND %d : TIME ACCELERATED ---" % manager.current_round
	
	# ==========================================
	# 2. ASCENSION BUFFS & MASS BLINDING
	# ==========================================
	user_card.attack_power += 50
	
	if "max_health" in user_card: user_card.max_health += 350
	user_card.health += 350
	
	if "max_defense" in user_card: user_card.max_defense += 200
	user_card.defense += 200
	
	if "evasion" in user_card: 
		user_card.evasion = 70
		
	if "tags" in user_card and not "Holy" in user_card.tags:
		user_card.tags.append("Holy")
		
	# ---> NEW: ARMOR PIERCING <---
	user_card.base_ignore_def = true
	user_card.outgoing_damage_type = "pierce"
	
	# ---> NEW: OVERRIDE ATTACK SOUND <---
	var mih_sfx = load("res://audio/sfx/mih.mp3")
	if mih_sfx != null:
		user_card.attack_sfx.clear()
		user_card.attack_sfx.append(mih_sfx)
	
	manager.log_event("🌟 " + user_card.card_name + "'s stats surge! (+50 ATK, +350 HP, +200 DEF, 70% EVASION, Pierce, [Holy])")

	# ==========================================
	# 3. BOSS MUSIC & TAG OVERRIDE
	# ==========================================
	if not ("is_boss" in user_card):
		user_card.set("is_boss", true) 
	else:
		user_card.is_boss = true
		
	user_card.boss_theme = load("res://audio/music/crucify.mp3")
	
	if manager.has_method("evaluate_boss_music"):
		manager.evaluate_boss_music()

	# ==========================================
	# 4. UNIVERSAL TARGETING (Infinite Range)
	# ==========================================
	user_card.is_orbital = true
	user_card.is_ranged = true
	user_card.is_anti_air = true
	user_card.has_depth_charge = true
	user_card.is_melee = false
	
	# ==========================================
	# 5. INJECT THE PASSIVE DYNAMICALLY
	# ==========================================
	# ---> FIX: Added "passive/" to the file path! <---
	var PassiveScript = load("res://passive/passive_madeinheaven.gd") 
	var mih_passive = PassiveScript.new()
	
	mih_passive.name = "PassiveMadeInHeaven"
	mih_passive.is_active = true
	mih_passive.card = user_card 
	
	user_card.passives.add_child(mih_passive)
	
	if mih_passive.has_method("start_heaven_environment"):
		mih_passive.start_heaven_environment(manager)

	user_card.ability_node = null 
	manager.update_ui(user_card)
	queue_free()
	
	return true
