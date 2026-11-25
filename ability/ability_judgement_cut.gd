extends BaseAbility

@export_group("Judgement Cut SFX")
@export var sfx_unsheathe: AudioStream # The slow sword draw (Bury the Light verse)
@export var sfx_slashes: AudioStream   # The rapid "shing-shing-shing"
@export var sfx_sheathe: AudioStream   # The final metallic "CLICK"
@export var sfx_shatter: AudioStream   # The glass breaking sound

func execute(user_card, target_card, manager) -> bool:
	if current_cooldown > 0:
		manager.log_event(ability_name + " is on cooldown for " + str(current_cooldown) + " turns!")
		return false

	manager.log_event("⚔️ \"Slay all...\" " + user_card.card_name + " enters their stance!")

	var valid_targets = []
	var all_cards = user_card.get_tree().get_nodes_in_group("cards")
	
	for c in all_cards:
		if is_instance_valid(c) and not c.is_queued_for_deletion():
			if c.is_player_card != user_card.is_player_card:
				if c.row != c.Row.HAND and not ("is_tower" in c and c.is_tower):
					valid_targets.append(c)

	if valid_targets.size() == 0:
		manager.log_event("⚠️ No valid targets for " + ability_name + " to cut!")
		return false

	var music_bus_idx = AudioServer.get_bus_index("Music")
	var was_music_muted = AudioServer.is_bus_mute(music_bus_idx)
	AudioServer.set_bus_mute(music_bus_idx, true)

	_play_sfx(manager, sfx_unsheathe)
	
	var dark_screen = ColorRect.new()
	dark_screen.color = Color(0, 0, 0, 0)
	dark_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark_screen.z_index = 100 
	dark_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	manager.add_child(dark_screen)

	var tween = manager.create_tween()
	tween.tween_property(dark_screen, "color", Color(0.02, 0.02, 0.1, 0.9), 1.0)
	
	await manager.get_tree().create_timer(2.5).timeout

	manager.log_event("YOU SHALL DIE !")
	_play_sfx(manager, sfx_slashes)

	var slash_container = Node2D.new()
	slash_container.z_index = 102
	manager.add_child(slash_container)

	for i in range(60):
		if not is_instance_valid(user_card): break 
		_create_persistent_slash(manager, slash_container)
		await manager.get_tree().create_timer(0.01).timeout

	await manager.get_tree().create_timer(2.0).timeout


	
	var distortion_container = Node2D.new()
	distortion_container.z_index = 101 # Right behind the slashes
	manager.add_child(distortion_container)
	
	_create_distortion_cracks(manager, distortion_container)
	
	for slash in slash_container.get_children():
		if slash is ColorRect:
			var t = manager.create_tween()
			t.set_parallel(true)
			t.tween_property(slash, "color", Color(0.01, 0.01, 0.05, 0.95), 2.0) # Turns to dark void
			t.tween_property(slash, "size:y", slash.size.y + 4.0, 2.0)           # Slowly widens

	await manager.get_tree().create_timer(3.0).timeout

	manager.log_event("\"...Judgement Cut END!\"")
	_play_sfx(manager, sfx_sheathe)
	_play_sfx(manager, sfx_shatter)

	_create_shatter_vfx(manager)

	dark_screen.color = Color(1, 1, 1, 1)
	var flash_tween = manager.create_tween()
	flash_tween.tween_property(dark_screen, "color", Color(1, 1, 1, 0), 0.5)

	if is_instance_valid(slash_container):
		slash_container.queue_free()
	if is_instance_valid(distortion_container):
		distortion_container.queue_free()

	for target in valid_targets:
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			target.take_damage(500, "pierce", user_card)
			target.attack_bump(target.global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20)))

	await manager.get_tree().create_timer(0.5).timeout
	if is_instance_valid(dark_screen):
		dark_screen.queue_free()

	AudioServer.set_bus_mute(music_bus_idx, was_music_muted)

	current_cooldown = max_cooldown
	return true



func _play_sfx(manager, stream: AudioStream):
	if stream != null:
		var player = AudioStreamPlayer.new()
		player.bus = "SFX"
		player.stream = stream
		manager.add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

func _create_persistent_slash(manager, container: Node):
	var slash = ColorRect.new()
	var is_white = (randi() % 4 == 0) 
	slash.color = Color(1.0, 1.0, 1.0, 0.95) if is_white else Color(0.3, 0.7, 1.0, 0.85) 
	
	var screen_size = manager.get_viewport_rect().size
	slash.size = Vector2(randf_range(800, 2000), randf_range(2, 6))
	slash.position = Vector2(randf_range(-200, screen_size.x), randf_range(-200, screen_size.y))
	slash.rotation = randf_range(0, TAU)
	slash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	container.add_child(slash)
	
	var t = manager.create_tween()
	slash.modulate = Color(1, 1, 1, 0)
	t.tween_property(slash, "modulate", Color(1, 1, 1, 1), 0.1)

func _create_distortion_cracks(manager, container: Node):
	var screen_size = manager.get_viewport_rect().size
	var center = screen_size / 2.0
	
	for i in range(12):
		var pane = Polygon2D.new()
		pane.color = Color(0.6, 0.8, 1.0, 0.15) # Very faint, frosted glass look
		
		var base_offset = Vector2(randf_range(-600, 600), randf_range(-400, 400))
		pane.polygon = PackedVector2Array([
			center + base_offset,
			center + base_offset + Vector2(randf_range(100, 900), randf_range(-400, 400)),
			center + base_offset + Vector2(randf_range(-400, 400), randf_range(100, 900)),
			center + base_offset + Vector2(randf_range(-300, 300), randf_range(-300, 300))
		])
		pane.modulate = Color(1, 1, 1, 0) # Start completely invisible
		container.add_child(pane)
		
		var t = manager.create_tween()
		t.tween_property(pane, "modulate", Color(1, 1, 1, 1), 1.5)

func _create_shatter_vfx(manager):
	var screen_size = manager.get_viewport_rect().size
	var center = screen_size / 2.0
	
	for i in range(15):
		var shard = Polygon2D.new()
		shard.color = Color(0.8, 0.9, 1.0, 0.7) 
		
		var base_offset = Vector2(randf_range(-300, 300), randf_range(-300, 300))
		shard.polygon = PackedVector2Array([
			center + base_offset,
			center + base_offset + Vector2(randf_range(50, 400), randf_range(-200, 200)),
			center + base_offset + Vector2(randf_range(-200, 200), randf_range(50, 400))
		])
		shard.z_index = 105
		manager.add_child(shard)
		
		var t = manager.create_tween()
		t.set_parallel(true)
		var dir = (shard.polygon[0] - center).normalized()
		var explosion_force = randf_range(300, 800)
		
		t.tween_property(shard, "position", dir * explosion_force, 0.6).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		t.tween_property(shard, "rotation", randf_range(-3, 3), 0.6)
		t.tween_property(shard, "color", Color(1, 1, 1, 0), 0.6)
		
		t.chain().tween_callback(shard.queue_free)
