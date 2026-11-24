extends BaseAbility

func _init():
	ability_name = "Void Blaster"
	is_free_action = true 
	requires_target = true

func execute(user_card, target_card, manager) -> bool:
	manager.log_event("\n🌌 >>> VOID BLASTER ACTIVATED <<< 🌌")
	manager.log_event("ccboatcc tears a hole in reality! A massive 10-second void beam fires at " + target_card.card_name + "!")

	# ==========================================
	# 1. APPLY VOID ARMOR & OVERCHARGE BUFF
	# ==========================================
	if "max_defense" in user_card: user_card.max_defense += 250
	user_card.defense += 250
	user_card.show_floating_text("+250 DEF", Color.CYAN)
	
	# ---> NEW: UNLOCK THE MULTI-MODE COMBO! <---
	var mode_manager = user_card.get_node_or_null("ModeManager")
	if mode_manager != null and "exhaust_only_after_all_modes" in mode_manager:
		mode_manager.exhaust_only_after_all_modes = true
		manager.log_event("⚔️ OVERCHARGE: ccboatcc's limiter is removed! He can now chain all of his modes!")
	
	if user_card.has_method("buff_animation"): 
		user_card.buff_animation()
		
	manager.log_event("🛡️ ccboatcc gains 250 Void Armor! He is free to advance his assault.")

	# ==========================================
	# 2. CALCULATE INITIAL TRAJECTORY
	# ==========================================
	var start_pos = user_card.global_position
	var dir = (target_card.global_position - start_pos).normalized()

	# We fire the beam asynchronously, letting it recalculate hits EVERY SECOND!
	_fire_beam_loop(user_card, manager, start_pos, dir, target_card)

	has_been_used = true
	return true

# ==========================================
# BACKGROUND DAMAGE ENGINE & VFX
# ==========================================
func _fire_beam_loop(attacker, manager, start_pos, dir, initial_target):
	var beam_node = Node2D.new()
	beam_node.z_index = 45 
	manager.add_child(beam_node)
	
	var beam_body = Node2D.new()
	beam_node.add_child(beam_body)

	var perp = Vector2(-dir.y, dir.x)
	
	# ---> NEW: Memorize whose side ccboatcc is on! <---
	# Even if he dies, the beam will remember who the enemies are.
	var attacker_is_player = attacker.is_player_card 

	# ==========================================
	# 1. GENERATE THE MINECRAFT VOID BEAM
	# ==========================================
	for d in range(0, 2500, 15): 
		for p_idx in range(6): 
			var p = ColorRect.new()
			var is_core = randi() % 5 < 3 
			var offset_mag = 0.0
			
			if is_core:
				offset_mag = randf_range(-25.0, 25.0) 
				p.color = Color(0.0, 0.0, 0.0, 1.0) if randi() % 2 == 0 else Color(0.08, 0.0, 0.15, 1.0)
				p.size = Vector2(28, 28) 
			else:
				offset_mag = (randf_range(-1.0, 1.0) + randf_range(-1.0, 1.0)) * 65.0
				p.color = Color(0.7, 0.0, 1.0, 0.9) if randi() % 2 == 0 else Color(0.9, 0.2, 1.0, 0.8)
				p.size = Vector2(16, 16)
				
			p.pivot_offset = p.size / 2.0
			p.position = start_pos + (dir * d) + (perp * offset_mag) - p.pivot_offset
			beam_body.add_child(p)
			
			var tw = beam_node.get_tree().create_tween().set_loops()
			var random_time = randf_range(0.1, 0.3)
			tw.tween_property(p, "scale", Vector2(1.2, 1.2), random_time)
			tw.parallel().tween_property(p, "modulate:a", randf_range(0.5, 1.0), random_time)
			tw.tween_property(p, "scale", Vector2(0.8, 0.8), random_time)

	# ==========================================
	# 2. THE 10-SECOND DAMAGE LOOP
	# ==========================================
	for i in range(10):
		if not is_instance_valid(manager) or manager.is_game_over:
			break

		var shake_tw = beam_node.get_tree().create_tween()
		shake_tw.tween_property(beam_body, "position", Vector2(randf_range(-12, 12), randf_range(-12, 12)), 0.05)
		shake_tw.tween_property(beam_body, "position", Vector2(0, 0), 0.05)

		for p_idx in range(45):
			var p = ColorRect.new()
			var is_black = randi() % 2 == 0
			var offset_mag = 0.0
			var random_drift = Vector2.ZERO

			if is_black:
				p.color = Color(0.0, 0.0, 0.0, 1.0)
				p.size = Vector2(24, 24)
				offset_mag = randf_range(-30, 30) 
				random_drift = Vector2(randf_range(-20, 20), randf_range(-20, 20)) 
			else:
				p.color = Color(0.8, 0.2, 1.0, 1.0)
				p.size = Vector2(16, 16)
				offset_mag = randf_range(-140, 140) 
				random_drift = Vector2(randf_range(-120, 120), randf_range(-120, 120)) 

			var dist_along_beam = randf_range(50, 2000)
			p.position = start_pos + (dir * dist_along_beam) + (perp * offset_mag)
			beam_node.add_child(p)

			var tw = beam_node.get_tree().create_tween()
			tw.tween_property(p, "position", p.position + random_drift, 0.8).set_trans(Tween.TRANS_SINE)
			tw.parallel().tween_property(p, "modulate:a", 0.0, 0.8)
			tw.tween_callback(p.queue_free)

		# ==========================================
		# 3. RECALCULATE TARGETS EVERY SECOND
		# ==========================================
		var current_targets = []
		var all_cards = manager.get_tree().get_nodes_in_group("cards")
		
		for c in all_cards:
			if is_instance_valid(c) and not c.is_queued_for_deletion():
				
				# ---> FIX: Use the memorized allegiance! <---
				var is_enemy = (c.is_player_card != attacker_is_player)
				
				if is_enemy and c.row != c.Row.HAND:
					# Safe check for initial target in case they died
					if is_instance_valid(initial_target) and c == initial_target:
						if not current_targets.has(c): current_targets.append(c)
						continue
					
					var vec_to_c = c.global_position - start_pos
					if vec_to_c.dot(dir) > -20.0: 
						var proj = vec_to_c.project(dir)
						var dist_to_line = (vec_to_c - proj).length()
						
						if dist_to_line <= 150.0:
							current_targets.append(c)

		# Apply Damage Tick
		for t in current_targets:
			if is_instance_valid(t) and not t.is_queued_for_deletion():
				var old_block = t.block_stacks if "block_stacks" in t else 0
				if "block_stacks" in t: t.block_stacks = 0

				var is_t = "is_tower" in t and t.is_tower
				var dmg_amount = 1 if is_t else 150
				var float_text = "-1 THP!" if is_t else "-150 VOID"

				var safe_attacker = attacker if is_instance_valid(attacker) else null
				
				# ---> FIX: FORCE RANGED ATTACK TO BYPASS MELEE COUNTERS <---
				var orig_melee = false
				if safe_attacker != null and "is_melee" in safe_attacker:
					orig_melee = safe_attacker.is_melee
					safe_attacker.is_melee = false # Disguise the attack!

				t.take_damage(dmg_amount, "pierce", safe_attacker)
				t.show_floating_text(float_text, Color(0.7, 0.1, 1.0))

				# Restore ccboatcc's original melee stat instantly
				if is_instance_valid(safe_attacker) and "is_melee" in safe_attacker:
					safe_attacker.is_melee = orig_melee

				if is_instance_valid(t) and not t.is_queued_for_deletion():
					if "block_stacks" in t: t.block_stacks = old_block

		if is_instance_valid(manager):
			await manager.get_tree().create_timer(1.0).timeout

	if is_instance_valid(beam_node):
		var cleanup_tw = beam_node.get_tree().create_tween()
		cleanup_tw.tween_property(beam_node, "modulate:a", 0.0, 1.5)
		cleanup_tw.tween_callback(beam_node.queue_free)
