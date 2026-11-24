extends BasePassive

func on_take_damage(amount: int, damage_type: String, attacker: Node):
	if attacker == null: return
	if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): return
	
	var a_melee = attacker.is_melee if "is_melee" in attacker else false
	
	if a_melee:
		await get_tree().create_timer(0.4).timeout 
		
		if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): return
		if not is_instance_valid(card) or card.is_queued_for_deletion(): return
		
		card.show_floating_text("COUNTER!", Color.GREEN)
		card.attack_bump(attacker.global_position)
		
		# ==========================================
		# 1. PLAY THE ATTACK SOUND EFFECT
		# ==========================================
		if "attack_sfx" in card and card.attack_sfx.size() > 0:
			var random_sfx = card.attack_sfx.pick_random()
			if random_sfx != null:
				var sfx_player = AudioStreamPlayer.new()
				sfx_player.bus = "SFX"
				sfx_player.stream = random_sfx
				card.add_child(sfx_player)
				sfx_player.play()
				sfx_player.finished.connect(sfx_player.queue_free)
		
		# ==========================================
		# 2. FULL-SCREEN TREE JUMPSCARE
		# ==========================================
		var jumpscare_layer = CanvasLayer.new()
		jumpscare_layer.layer = 100 # Put it on the very front layer!
		
		var tex_rect = TextureRect.new()
		tex_rect.texture = load("res://images/tree.jpg") # Make sure the path matches!
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Stretch across the whole screen
		
		jumpscare_layer.add_child(tex_rect)
		card.add_child(jumpscare_layer)
		
		# Set a timer to delete the jumpscare after exactly 2 seconds
		get_tree().create_timer(2.0).timeout.connect(jumpscare_layer.queue_free)
		
		# ==========================================
		# 3. APPLY DAMAGE TO ATTACKER
		# ==========================================
		await get_tree().create_timer(0.1).timeout
		
		# ---> NEW: Catch the ghost if the first burst counter-attack already killed him! <---
		if not is_instance_valid(attacker) or attacker.is_queued_for_deletion():
			return
		
		var old_block = attacker.block_stacks
		var old_parry = attacker.parry_stacks
		
		attacker.block_stacks = 0
		attacker.parry_stacks = 0
		
		var dmg = card.attack_power
		var synergy_manager = card.get_parent().get_node_or_null("SynergyManager")
		
		if synergy_manager != null:
			dmg = synergy_manager.calculate_synergy_damage(card, attacker, dmg, card.outgoing_damage_type)
		
		if dmg > 0:
			attacker.take_damage(dmg, card.outgoing_damage_type, card)
		
		# Safety check before restoring block stacks!
		if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
			attacker.block_stacks = old_block
			attacker.parry_stacks = old_parry
