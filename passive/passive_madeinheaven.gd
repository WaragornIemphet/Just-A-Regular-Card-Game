extends BasePassive

var heaven_env: Node2D = null
var day_night_rect: ColorRect = null
var streak_timer: Timer = null

func _exit_tree():
	if is_instance_valid(heaven_env):
		heaven_env.queue_free()

func start_heaven_environment(manager: Node):
	play_pucci_slice_vfx(card.global_position, manager)
	
	heaven_env = Node2D.new()
	heaven_env.z_index = 50 # Sits slightly above the board, below the UI!
	manager.add_child(heaven_env)
	
	day_night_rect = ColorRect.new()
	day_night_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day_night_rect.size = Vector2(4000, 4000)
	day_night_rect.position = Vector2(-1000, -1000)
	day_night_rect.color = Color(1.0, 1.0, 1.0, 1.0) 
	
	var mat = CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_MUL
	day_night_rect.material = mat
	heaven_env.add_child(day_night_rect)
	
	_loop_day_night()
	
	streak_timer = Timer.new()
	streak_timer.wait_time = 0.05 
	streak_timer.autostart = true
	streak_timer.timeout.connect(_spawn_fast_forward_streak)
	heaven_env.add_child(streak_timer)

func _loop_day_night():
	if not is_instance_valid(day_night_rect): return
	var t = day_night_rect.get_tree().create_tween()
	
	var day = Color(1.0, 1.0, 1.0, 1.0)
	var sunset = Color(1.0, 0.85, 0.6, 1.0) # ---> Pale Golden Yellow (no heavy orange!)
	var night = Color(0.3, 0.3, 0.6, 1.0)   # ---> Deep dark blue
	
	t.tween_property(day_night_rect, "color", sunset, 0.3)
	t.tween_property(day_night_rect, "color", night, 0.3)
	t.tween_property(day_night_rect, "color", sunset, 0.3)
	t.tween_property(day_night_rect, "color", day, 0.3)
	t.finished.connect(_loop_day_night)

func _spawn_fast_forward_streak():
	if not is_instance_valid(heaven_env): return
	var streak = ColorRect.new()
	streak.color = Color(1.0, 1.0, 1.0, randf_range(0.3, 0.8))
	streak.size = Vector2(randf_range(150, 400), randf_range(2, 6))
	
	var start_y = randf_range(0, 1080)
	streak.position = Vector2(-500, start_y)
	heaven_env.add_child(streak)
	
	var t = heaven_env.get_tree().create_tween()
	
	t.tween_property(streak, "position:x", 3000.0, randf_range(0.15, 0.3))
	
	t.tween_callback(streak.queue_free)

func _spawn_dash_afterimages(start_pos: Vector2, end_pos: Vector2, manager: Node):
	var tex = null
	if card.has_node("Sprite2D"): tex = card.get_node("Sprite2D").texture
	elif "texture" in card: tex = card.texture
	if tex == null: return
	
	for i in range(5):
		var frac = float(i) / 4.0
		var spawn_pos = start_pos.lerp(end_pos, frac)
		
		var ghost = Sprite2D.new()
		ghost.texture = tex
		ghost.global_position = spawn_pos
		ghost.scale = card.scale if "scale" in card else Vector2(1, 1)
		
		ghost.modulate = Color(0.4, 0.9, 1.0, 0.6)
		ghost.z_index = card.z_index - 1
		manager.add_child(ghost)
		
		var t = manager.get_tree().create_tween()
		t.tween_property(ghost, "modulate:a", 0.0, 0.4).set_delay(i * 0.05)
		t.tween_callback(ghost.queue_free)

func on_attack(target: Node, damage: int):
	var manager = card.get_tree().current_scene
	if manager == null: return
	
	manager.log_event("⏱️ " + card.card_name + " strikes everywhere at once!")
	var all_cards = manager.get_tree().get_nodes_in_group("cards")
	
	_spawn_dash_afterimages(card.global_position, target.global_position, manager)
	
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion() and c != target:
			if c.is_player_card != card.is_player_card and c.row != c.Row.HAND:
				if not ("is_tower" in c and c.is_tower):
					play_pucci_slice_vfx(c.global_position, manager)
					c.take_damage(damage, card.outgoing_damage_type, card)

func on_take_damage(amount: int, damage_type: String, attacker: Node):
	if not is_instance_valid(attacker) or attacker.is_queued_for_deletion(): return
	var manager = card.get_tree().current_scene
	if manager == null: return
	
	var a_melee = attacker.is_melee if "is_melee" in attacker else false
	
	if a_melee:
		manager.log_event("⏱️ " + card.card_name + " accelerated behind " + attacker.card_name + "!")
		
		_spawn_dash_afterimages(card.global_position, attacker.global_position, manager)
		play_pucci_slice_vfx(attacker.global_position, manager)
		
		if manager.has_method("play_attack_sound"):
			manager.play_attack_sound(card)
		
		var old_block = attacker.block_stacks
		var old_parry = attacker.parry_stacks
		attacker.block_stacks = 0
		attacker.parry_stacks = 0
		
		var counter_dmg = card.attack_power * 2.5
		attacker.take_damage(counter_dmg, "pierce", card)
		
		if is_instance_valid(attacker) and not attacker.is_queued_for_deletion():
			attacker.block_stacks = old_block
			attacker.parry_stacks = old_parry

func on_turn_start():
	var manager = card.get_tree().current_scene
	if manager == null: return
	
	var is_my_turn = (manager.current_turn == manager.Turn.PLAYER and card.is_player_card) or (manager.current_turn == manager.Turn.ENEMY and not card.is_player_card)
	
	if is_my_turn:
		manager.current_round += 1
		manager.log_event("⏳ Time continues to accelerate... (+1 Round)")

func play_pucci_slice_vfx(pos: Vector2, manager: Node):
	var vfx = Node2D.new()
	vfx.z_index = 100 
	manager.add_child(vfx)
	
	var t = manager.get_tree().create_tween()
	t.set_parallel(true)
	
	var flash = ColorRect.new()
	flash.color = Color(1.0, 1.0, 1.0, 1.0)
	flash.size = Vector2(100, 100)
	flash.position = pos - Vector2(50, 50)
	vfx.add_child(flash)
	
	t.tween_property(flash, "scale", Vector2(0, 0), 0.2).set_trans(Tween.TRANS_EXPO)
	t.tween_property(flash, "color", Color(1, 1, 1, 0), 0.2)
	
	for i in range(4):
		var slash = ColorRect.new()
		slash.color = Color(1.0, 0.9, 0.1, 1.0) if i % 2 == 0 else Color(0.2, 0.9, 1.0, 0.9)
		slash.size = Vector2(randf_range(300, 600), randf_range(3, 8))
		
		slash.pivot_offset = slash.size / 2.0
		slash.position = pos - slash.pivot_offset + Vector2(randf_range(-40, 40), randf_range(-40, 40))
		slash.rotation = randf_range(-0.8, 0.8)
		vfx.add_child(slash)
		
		t.tween_property(slash, "scale:x", 1.5, 0.2).set_delay(i * 0.03)
		t.tween_property(slash, "scale:y", 0.0, 0.2).set_delay(i * 0.03)
	
	for i in range(15):
		var spark = ColorRect.new()
		spark.color = Color(0.8, 0.0, 0.1, 1.0) if randi() % 2 == 0 else Color(1.0, 1.0, 1.0, 1.0)
		spark.size = Vector2(6, 6)
		spark.position = pos - Vector2(3, 3)
		vfx.add_child(spark)
		
		var angle = randf_range(0, TAU)
		var dir = Vector2(cos(angle), sin(angle))
		var dist = randf_range(80, 150)
		
		t.tween_property(spark, "position", pos + dir * dist, 0.3).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		t.tween_property(spark, "scale", Vector2(0, 0), 0.3)

	t.chain().tween_callback(vfx.queue_free)
func play_evade_animation():
	var manager = card.get_tree().current_scene
	if manager == null: return
	
	var original_pos = card.position
	var t = manager.get_tree().create_tween()
	t.tween_property(card, "position", original_pos + Vector2(25, 0), 0.03)
	t.tween_property(card, "position", original_pos + Vector2(-25, 0), 0.03)
	t.tween_property(card, "position", original_pos + Vector2(15, 0), 0.03)
	t.tween_property(card, "position", original_pos + Vector2(-15, 0), 0.03)
	t.tween_property(card, "position", original_pos, 0.03)
	
	var tex = null
	if card.has_node("Sprite2D"): tex = card.get_node("Sprite2D").texture
	elif "texture" in card: tex = card.texture
	if tex == null: return
	
	for i in range(4):
		var ghost = Sprite2D.new()
		ghost.texture = tex
		ghost.global_position = card.global_position
		ghost.scale = card.scale if "scale" in card else Vector2(1, 1)
		
		ghost.modulate = Color(0.4, 0.9, 1.0, 0.8) # Bright Cyan glow
		ghost.z_index = card.z_index - 1
		manager.add_child(ghost)
		
		var gt = manager.get_tree().create_tween()
		gt.set_parallel(true)
		
		var angle = randf_range(0, TAU)
		var dir = Vector2(cos(angle), sin(angle))
		var dist = randf_range(50, 100)
		
		gt.tween_property(ghost, "global_position", card.global_position + dir * dist, 0.25).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		gt.tween_property(ghost, "modulate:a", 0.0, 0.25)
		
		gt.chain().tween_callback(ghost.queue_free)
